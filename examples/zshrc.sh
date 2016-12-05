# proxy setup
function setp(){
  export http_proxy='http://127.0.0.1:7777'
  export https_proxy='http://127.0.0.1:7777'
  echo "HTTP Proxy on"
}
function unsetp(){
  unset http_proxy
  unset https_proxy
  echo "HTTP Proxy off"
}

# port and tcp/udp
function port() { lsof -i tcp:$1 }
function ports() { lsof -Pni4 | grep LISTEN }
function tcp() {
  lsof -n -P -i TCP
}
function udp() {
  lsof -n -P -i UDP
}

# kext load and unload
function kl() {
  file_name=$1
  name=${file_name%.*}
  sudo chmod -R 755 $1
  sudo chown -R root:wheel $1
  sudo kextload $1
  kextstat | grep name
}
function kul() {
  file_name=$1
  name=${file_name%.*}
  sudo kextunload $1
  sudo rm -rf $1
  kextstat | grep name
}

# uninstall rubymine completely
function cleanup_rubymine() {
  rm -rf ~/Library/Caches/RubyMine*
  rm -rf ~/Library/Preferences/RubyMine*
  rm -rf ~/Library/Logs/RubyMine*
}

# one line http server
function one_line_server_sinatra() {
  ruby -rsinatra -e'set :public_folder, "."; set :port, 8000; set :bind, "0.0.0.0"'
}
function one_line_server_httpd() {
  ruby -run -ehttpd . -p8000 -b0.0.0.0
}

# mysql backup all db
alias bg="mysqldump -u root -p --all-databases > all_databases.sql"

# rails alias
alias rs="rails server webrick -b 0.0.0.0 -p 3000"
alias rc="rails c"
