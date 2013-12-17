export RAILS_ENV=test
export GEM_PATH=./vendor/bundle
export GEMS_TAR_FILE=/tmp/JOB_NAME_gems.tar.gz
export GEMFILE_SHA_FILE=/tmp/JOB_NAME_gemfile.sha
export GEMS_SHA_FILE=/tmp/JOB_NAME_gems.sha

git clone --depth 1 GIT_REMOTE_ORIGIN .
git checkout GIT_BRANCH

find config -name '*.yml.example' | sed "p;s/.example//" | xargs -n2 cp

export GEMS_SHA_CALCULATED="$(shasum $GEMS_TAR_FILE)"
export GEMS_SHA="$(cat $GEMS_SHA_FILE)"
export GEMFILE_SHA_CALCULATED="$(shasum Gemfile)"
export GEMFILE_SHA="$(cat $GEMFILE_SHA_FILE)"
export GEM_FILES_EXIST=$([ -f "$GEMS_TAR_FILE" ] && [ -f "$GEMS_SHA_FILE" ] && [ -f "$GEMFILE_SHA_FILE" ] && [ -f "/tmp/JOB_NAME_gems.tar.gz" ] && echo 1)
export HAS_GEMS_TARBALL=$([ -n "$GEM_FILES_EXIST" ] && [ "$GEMS_SHA_CALCULATED" = "$GEMS_SHA" ] && [ "$GEMFILE_SHA_CALCULATED" = "$GEMFILE_SHA" ] && echo 1)

if [ -n "$HAS_GEMS_TARBALL" ]
then mkdir "$GEM_PATH"
  cd "$GEM_PATH"
  tar -zxvf $GEMS_TAR_FILE
  cd -
  bundle --deployment
else bundle --deployment
  echo 'bundle installed'
  echo 'saving gems for next time'
  cd "$GEM_PATH"
  tar -zcvf $GEMS_TAR_FILE .
  cd -
  shasum $GEMS_TAR_FILE > $GEMS_SHA_FILE
  shasum Gemfile > $GEMFILE_SHA_FILE
  echo 'gems updated'
fi

[ -d "coverage" ] && rm -rf coverage
mkdir coverage

bundle exec rake db:create --trace
bundle exec rake db:schema:load --trace
bundle exec rake spec:run_once --trace
