# KPort build integration layer
#
# Adapts kde-builder's module resolution and dependency graph for KPort's
# USE flag + pacscript generation workflow.
#
# Upstream source: vendor/kde-builder/kde_builder_lib/
# Update vendor with:
#   GIT_EXEC_PATH=/usr/lib/git-core git subtree pull \
#     --prefix=vendor/kde-builder kde-builder master --squash
