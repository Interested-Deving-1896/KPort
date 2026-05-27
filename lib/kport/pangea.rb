# lib/kport/pangea.rb
#
# KDE Neon Pangea Tooling conventions for KPort.
#
# Provides helpers for:
#   - Mapping KPort package names ↔ Neon archive/Jenkins identifiers
#   - Parsing and comparing Neon version strings
#   - Querying the Neon apt archive for latest package versions
#   - Querying the Jenkins CI API for build status
#
# All network calls are lazy and cached per-process. Set KPORT_NO_NETWORK=1
# to disable outbound requests (returns nil for network-dependent methods).

require 'yaml'
require 'net/http'
require 'uri'
require 'zlib'
require 'json'
require 'time'

module KPort
  module Pangea
    CONFIG_PATH = File.expand_path('../../../config/pangea.yml', __FILE__).freeze

    # ── Configuration ──────────────────────────────────────────────────────

    # Returns the parsed pangea.yml config hash (memoised).
    def self.config
      @config ||= YAML.safe_load_file(CONFIG_PATH, permitted_classes: [Symbol])
    end

    # ── Channel helpers ────────────────────────────────────────────────────

    # Returns the Neon archive name for a KPort channel.
    #   pangea_channel('stable')    # => "release"
    #   pangea_channel('unstable')  # => "unstable"
    def self.pangea_channel(kport_channel)
      ch = config.dig('channels', kport_channel.to_s)
      raise ArgumentError, "Unknown channel: #{kport_channel}" unless ch
      ch['neon_name']
    end

    # Returns the KPort channel name for a Neon archive name.
    #   kport_channel('release')    # => "stable"
    def self.kport_channel(neon_name)
      config['channels'].each do |kport_name, ch|
        return kport_name if ch['neon_name'] == neon_name.to_s
      end
      raise ArgumentError, "Unknown Neon channel name: #{neon_name}"
    end

    # Returns the package suffix for a channel (e.g. "" for stable, "-unstable").
    def self.channel_suffix(kport_channel)
      config.dig('channels', kport_channel.to_s, 'package_suffix') || ''
    end

    # ── Package name mapping ───────────────────────────────────────────────

    # Returns the Neon archive package name for a KPort package + channel.
    # Stable packages have no suffix; unstable/nightly get a channel suffix.
    #
    #   pangea_name('kf6-karchive', 'stable')    # => "kf6-karchive"
    #   pangea_name('kf6-karchive', 'unstable')  # => "kf6-karchive-unstable"
    def self.pangea_name(kport_name, channel = 'stable')
      suffix = channel_suffix(channel)
      suffix.empty? ? kport_name.to_s : "#{kport_name}#{suffix}"
    end

    # Strips a channel suffix from a Neon package name and returns
    # [kport_name, channel] pair.
    #
    #   kport_name('kf6-karchive-unstable')  # => ["kf6-karchive", "unstable"]
    #   kport_name('kf6-karchive')           # => ["kf6-karchive", "stable"]
    def self.kport_name(neon_pkg_name)
      name = neon_pkg_name.to_s
      config['channels'].each do |kport_channel, ch|
        suffix = ch['package_suffix']
        next if suffix.nil? || suffix.empty?
        if name.end_with?(suffix)
          return [name[0..-(suffix.length + 1)], kport_channel]
        end
      end
      [name, 'stable']
    end

    # ── Version parsing ────────────────────────────────────────────────────

    # Parses a Neon version string into its components.
    # Returns a hash with keys :upstream, :neon_patch, :snapshot (may be nil).
    # Returns nil if the string does not match the Neon version pattern.
    #
    #   parse_version('6.3.0+p24.04+git20250501T120000Z')
    #   # => { upstream: "6.3.0", neon_patch: "24.04", snapshot: "20250501T120000Z" }
    def self.parse_version(version_str)
      pattern = Regexp.new(config.dig('version', 'pattern'))
      m = pattern.match(version_str.to_s)
      return nil unless m
      {
        upstream:    m[:upstream],
        neon_patch:  m[:neon_patch],
        snapshot:    m[:snapshot]
      }
    end

    # Extracts just the upstream version component from a Neon version string.
    # Falls back to the full string if it doesn't match the Neon pattern
    # (handles plain upstream versions like "6.3.0").
    def self.upstream_version(version_str)
      parsed = parse_version(version_str)
      parsed ? parsed[:upstream] : version_str.to_s
    end

    # Compares two Neon version strings by their upstream component.
    # Returns -1, 0, or 1 (compatible with Array#sort).
    #
    # Falls back to lexicographic comparison if Gem::Version raises.
    def self.compare_versions(v1, v2)
      u1 = upstream_version(v1)
      u2 = upstream_version(v2)
      Gem::Version.new(u1) <=> Gem::Version.new(u2)
    rescue ArgumentError
      u1 <=> u2
    end

    # ── Component group resolution ─────────────────────────────────────────

    # Returns the component group name for a package (e.g. "frameworks").
    # Matches against prefix lists in config; returns "misc" if no match.
    #
    #   component_group('kf6-karchive')  # => "frameworks"
    #   component_group('plasma-desktop') # => "plasma"
    def self.component_group(package)
      name = package.to_s
      config['component_groups'].each do |group, cfg|
        next if group == 'misc'
        prefixes = cfg['prefixes'] || []
        return group if prefixes.any? { |p| name.start_with?(p) }
      end
      'misc'
    end

    # Returns the Jenkins path segment for a package's component group.
    #   component_jenkins_path('kf6-karchive')  # => "frameworks"
    def self.component_jenkins_path(package)
      group = component_group(package)
      config.dig('component_groups', group, 'jenkins_path') || group
    end

    # ── systemd / Devuan helpers ───────────────────────────────────────────

    # Returns true if the package has a hard systemd dependency per config.
    def self.systemd_dependent?(package)
      (config['systemd_dependent'] || []).include?(package.to_s)
    end

    # Returns the Devuan substitute for a package, or nil if none defined.
    # Returns "" (empty string) if the package should be masked/skipped.
    def self.devuan_substitute(package)
      subs = config['devuan_substitutions'] || {}
      subs.key?(package.to_s) ? subs[package.to_s] : nil
    end

    # ── Jenkins integration ────────────────────────────────────────────────

    # Returns the Jenkins job path for a package + channel.
    #   jenkins_job('kf6-karchive', 'stable')
    #   # => "/job/neon/job/Release/job/frameworks/job/kf6-karchive/"
    def self.jenkins_job(package, channel = 'stable')
      ch_cfg   = config.dig('channels', channel.to_s)
      raise ArgumentError, "Unknown channel: #{channel}" unless ch_cfg
      folder    = ch_cfg['jenkins_folder']
      component = component_jenkins_path(package)
      template  = config.dig('jenkins', 'job_path_template')
      template % { channel: folder, component: component, package: package }
    end

    # Returns the full Jenkins API URL for a package + channel.
    #   jenkins_url('kf6-karchive', 'stable')
    #   # => "https://build.neon.kde.org/job/neon/job/Release/job/frameworks/job/kf6-karchive/api/json"
    def self.jenkins_url(package, channel = 'stable', tree: nil)
      base    = config.dig('jenkins', 'base_url')
      job     = jenkins_job(package, channel)
      suffix  = config.dig('jenkins', 'api_suffix')
      url     = "#{base}#{job}#{suffix}"
      url    += "?tree=#{URI.encode_www_form_component(tree)}" if tree
      url
    end

    # Queries the Jenkins API for the last build status of a package.
    # Returns a hash:
    #   {
    #     result:    "SUCCESS" | "FAILURE" | "UNSTABLE" | nil,
    #     timestamp: Time | nil,
    #     url:       String | nil,
    #     number:    Integer | nil
    #   }
    # Returns nil on network error or if KPORT_NO_NETWORK is set.
    def self.build_status(package, channel = 'stable')
      return nil if ENV['KPORT_NO_NETWORK']
      tree = config.dig('jenkins', 'last_build_tree')
      url  = jenkins_url(package, channel, tree: tree)
      body = _http_get(url)
      return nil unless body
      data = JSON.parse(body)
      lb   = data['lastBuild'] || {}
      ts   = lb['timestamp'] ? Time.at(lb['timestamp'] / 1000.0) : nil
      {
        result:    lb['result'],
        timestamp: ts,
        url:       lb['url'],
        number:    lb['number']
      }
    rescue JSON::ParserError, KeyError
      nil
    end

    # ── Archive / apt integration ──────────────────────────────────────────

    # Returns the base archive URL for a channel.
    #   archive_url('stable')
    #   # => "https://archive.neon.kde.org/release"
    def self.archive_url(channel = 'stable')
      neon = pangea_channel(channel)
      "#{config.dig('archive', 'base_url')}/#{neon}"
    end

    # Returns the Packages.gz URL for a channel + arch.
    def self.packages_url(channel = 'stable', arch = 'amd64')
      suite    = config.dig('channels', channel.to_s, 'archive_suite')
      template = config.dig('archive', 'packages_path')
      path     = template % { suite: suite, arch: arch }
      "#{archive_url(channel)}/#{path}"
    end

    # Fetches and parses the Neon apt Packages.gz for a channel + arch.
    # Returns a hash of { package_name => version_string } for all packages
    # whose names match the given prefix (or all packages if prefix is nil).
    #
    # Results are cached in @packages_cache keyed by "channel/arch".
    # Returns nil on network error or if KPORT_NO_NETWORK is set.
    def self.packages_index(channel = 'stable', arch = 'amd64')
      return nil if ENV['KPORT_NO_NETWORK']
      @packages_cache ||= {}
      key = "#{channel}/#{arch}"
      return @packages_cache[key] if @packages_cache.key?(key)

      url  = packages_url(channel, arch)
      data = _http_get(url, compressed: true)
      return nil unless data

      index = {}
      current_pkg = nil
      data.each_line do |line|
        line.chomp!
        if line.start_with?('Package: ')
          current_pkg = line[9..]
        elsif line.start_with?('Version: ') && current_pkg
          index[current_pkg] = line[9..]
          current_pkg = nil
        end
      end
      @packages_cache[key] = index
    end

    # Returns the latest version of a package in the Neon archive.
    # Queries the Packages.gz index for the given channel and arch.
    #
    #   latest_version('kf6-karchive', 'stable')
    #   # => "6.3.0+p24.04+git20250501T120000Z"
    #
    # Returns nil if the package is not found or network is unavailable.
    def self.latest_version(package, channel = 'stable', arch = 'amd64')
      index = packages_index(channel, arch)
      return nil unless index
      neon_pkg = pangea_name(package, channel)
      index[neon_pkg]
    end

    # Returns true if the Neon archive has a newer version than +current+.
    # Returns nil if the archive cannot be queried.
    def self.update_available?(package, current_version, channel = 'stable', arch = 'amd64')
      latest = latest_version(package, channel, arch)
      return nil unless latest
      compare_versions(latest, current_version) > 0
    end

    # ── Cache management ───────────────────────────────────────────────────

    # Clears all in-process caches (config, packages index).
    # Useful in tests or after a `kport sync`.
    def self.clear_cache!
      @config          = nil
      @packages_cache  = nil
    end

    # ── Private helpers ────────────────────────────────────────────────────

    # Performs an HTTP GET with up to 3 retries on 429/503.
    # Returns the response body as a String, or nil on failure.
    # If +compressed: true+, decompresses gzip response body.
    def self._http_get(url, compressed: false, retries: 3)
      uri = URI.parse(url)
      attempt = 0
      begin
        attempt += 1
        Net::HTTP.start(uri.host, uri.port,
                        use_ssl: uri.scheme == 'https',
                        open_timeout: 10,
                        read_timeout: 30) do |http|
          req = Net::HTTP::Get.new(uri.request_uri)
          req['User-Agent'] = 'KPort/1.0 (https://github.com/Interested-Deving-1896/KPort)'
          res = http.request(req)
          case res.code.to_i
          when 200
            body = res.body
            return compressed ? Zlib::GzipReader.new(StringIO.new(body)).read : body
          when 429, 503
            raise "rate_limited" if attempt >= retries
            sleep(2 ** attempt)
            retry
          else
            return nil
          end
        end
      rescue => e
        return nil if attempt >= retries
        sleep(1)
        retry
      end
    end
    private_class_method :_http_get
  end
end
