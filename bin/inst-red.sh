#!/bin/bash
#
# inst-red.sh
#
#

user=redmine
host=localhost
pw=redmine!pw1

function getpkg(){
    username=$1
    hostname=$2
    pw=$3

    # 必要なパッケージのインストール
    sudo apt update
    sudo apt install -y build-essential zlib1g-dev libssl-dev libreadline-dev libyaml-dev libcurl4-openssl-dev libffi-dev mysql-server mysql-client apache2 apache2-dev libapr1-dev libaprutil1-dev imagemagick libmagick++-dev fonts-takao-pgothic subversion git ruby libruby ruby-dev libmysqlclient-dev

    # passengerのインストールと有効化
    sudo apt-get install libapache2-mod-passenger
    sudo a2enmod passenger

    # gemで必要なライブラリをインストール
    sudo gem install bundler racc mysql2

    # MySQLでユーザーを作成
    echo "enter password for root of linux."
    sudo mysql -u root -p <<EOF
    CREATE DATABASE redmine character set utf8mb4;
    CREATE USER '$username'@'$hostname' IDENTIFIED BY '$pw';
    GRANT ALL ON redmine.* TO '$username'@'$hostname';
    flush privileges;
    exit
EOF
}

function checkout(){
    # redmineを取得
    sudo mkdir /var/lib/redmine
    sudo chown www-data /var/lib/redmine
    echo "input www-data password."
    sudo -u www-data svn co https://svn.redmine.org/redmine/branches/4.2-stable /var/lib/redmine
    
    sudo cp /var/lib/redmine/config/database.yml.example /var/lib/redmine/config/database.yml
    # sudo vi /var/lib/redmine/config/database.yml
    x=' # productionを以下のように編集
    production:
    adapter: mysql2
    database: redmine
    host: localhost
    username: redmine
    password: "9dsj890cdn43nldsas*ncdsa342njD(SDca"
    encoding: utf8mb4
    '
    echo $x
    echo "Edit /var/lib/redmine/config/database.yml"
}

function setup(){
    # 必要なセットアップを実行。DBの登録もここで。
    cd /var/lib/redmine
    sudo -u www-data bundle install --without development test --path vendor/bundle
    sudo -u www-data bundle exec rake generate_secret_token
    sudo -u www-data RAILS_ENV=production bundle exec rake db:migrate
    sudo -u www-data RAILS_ENV=production REDMINE_LANG=ja bundle exec rake redmine:load_default_data

    # apacheの設定ファイルを作成
    cat <<- __EOF__ | sudo tee -a /etc/apache2/sites-available/redmine.conf
Alias /redmine /var/lib/redmine/public
<Location /redmine>
PassengerBaseURI /redmine
PassengerAppRoot /var/lib/redmine
Require all granted
</Location>
__EOF__

    # 上記で作成したredmine.confを有効化
    sudo a2ensite redmine.conf
    sudo systemctl reload apache2.service

    # 必要に応じて実行。192.168.1.0/24は、対象のネットワークに合わせて修正すること。
    sudo ufw allow from 192.168.1.0/24 to any app Apache
    sudo ufw status unmbered
    #
    # EOF
    #
}



function pre(){
    getpkg $user $hostname $pw
    checkout
}

function post(){
    setup 
}

function domain(){
    pre redmine localhost
    # edit configuration.yml
    checkout
    setup
    sudo apachctl configtest
    sudo apachctl restart
}

# pre <EDIT configuration.yml> post

for x in "$@" ; do
    $x
done



