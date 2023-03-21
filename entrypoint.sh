#!/bin/bash

# Required environment variables:
#
#   DEPLOY_KEY          SSH private key
#
#   DEPLOY_REPO         GitHub Pages repository
#   DEPLOY_BRANCH       GitHub Pages publishing branch
#
#   HUGO_VERSION        Hugo version
#
#   GITHUB_ACTOR        GitHub username
#   GITHUB_REPOSITORY   GitHub repository (source code)
#   GITHUB_WORKSPACE    GitHub workspace
#
#   TZ                  Timezone

set -e

# Install Hugo, default version is 0.111.2
HUGO_VERSION="${HUGO_VERSION:-0.111.2}"

wget -O ${HOME}/hugo.deb https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb \
          && sudo dpkg -i ${HOME}/hugo.deb    

REMOTE_REPO="git@github.com:${DEPLOY_REPO}.git"
REMOTE_BRANCH="${DEPLOY_BRANCH}"
GITHUB_WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"

git config --global user.name "${GITHUB_ACTOR}"
git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"

# https://github.com/reuixiy/hugo-theme-meme/issues/27
git config --global core.quotePath false

ln -s /usr/share/zoneinfo/${TZ} /etc/localtime

mkdir --parents /root/.ssh
ssh-keyscan -t rsa github.com > /root/.ssh/known_hosts && \
echo "${DEPLOY_KEY}" > /root/.ssh/id_rsa && \
chmod 400 /root/.ssh/id_rsa

git config --global --add safe.directory ${GITHUB_WORKSPACE}
cd ${GITHUB_WORKSPACE}

git clone --recurse-submodules "git@github.com:${GITHUB_REPOSITORY}.git" site && \
cd site

hugo --gc --minify --cleanDestinationDir

pushd public \
&& git init \
&& git remote add origin $REMOTE_REPO \
&& git add -A \
&& git checkout -b $REMOTE_BRANCH \
&& git commit -m "Automated deployment @ $(date '+%Y-%m-%d %H:%M:%S') ${TZ}" \
&& git push -f origin $REMOTE_BRANCH \
&& popd

rm -rf /root/.ssh
