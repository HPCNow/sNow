## sNow! documentation website repo
Execute the following commands to test the changes performed before to push any changes in the master branch:

```
scl enable rh-ruby22 bash
git fetch
git checkout -b release-X.Y.Z
git pull
JEKYLL_ENV=production bundle exec jekyll serve
```

In order to visualise the changes, create a SSH tunnel and open this URL (http://localhost:22080) with your web browser:

```
ssh -L 22080:localhost:4000 USER@SERVER.hpcnow.com -p X
```

## Requirements
1. Install ruby as root:
```
yum install gcc zlib-devel
yum -y install centos-release-scl-rh centos-release-scl
yum --enablerepo=centos-sclo-rh -y install rh-ruby22 rh-ruby22-ruby-devel
```

2. Install ruby dependencies as user:
```
scl enable rh-ruby22 bash
gem install bundler
```

3. Clone the snow-documentation repository:
```
git clone https://github.com/HPCNow/snow-documentation.git
```

4. Install Jekyll dependencies:

```
cd snow-documentation/
bundle install
```
