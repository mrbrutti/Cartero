# Functions borrowed it from DarkOperator MSF-Installer script. 
# Original source: https://github.com/darkoperator/MSF-Installer/blob/master/msf_install.sh
# They were just too good not to be re-used. 
# It is important to notice that Cartero can run on any version of ruby, 
# but we will default to 1.9.3 given it is what metasploit uses. 
# Thanks :-)
function print_good ()
{
    echo -e "\x1B[01;32m[*]\x1B[0m $1"
}
########################################

function print_error ()
{
    echo -e "\x1B[01;31m[*]\x1B[0m $1"
}
########################################

function print_status ()
{
    echo -e "\x1B[01;34m[*]\x1B[0m $1"
}

function usage ()
{
    echo "Cartero Framework Installer"
    echo "Matias P. Brutti - @S9Labs"
    echo "Ver 0.1"
    echo ""
    echo "-r                :Installs Ruby using Ruby Version Manager."
    echo "-h                :This help message"
}

function check_for_brew_osx
{
    print_status "Verifying that Homebrew is installed:"
    if [ -e /usr/local/bin/brew ]; then
        print_good "Homebrew is installed on the system, updating formulas."
        /usr/local/bin/brew update >> $LOGFILE 2>&1
        print_good "Finished updating formulas"
        brew tap homebrew/versions >> $LOGFILE 2>&1
        print_status "Verifying that the proper paths are set"

        if [ -d ~/.bash_profile ]; then
            if [ "$(grep ":/usr/local/sbin" ~/.bash_profile -q)" ]; then
                print_good "Paths are properly set"
            else
                print_status "Setting the path for homebrew"
                echo PATH=/usr/local/bin:/usr/local/sbin:$PATH >> ~/.bash_profile
                source  ~/.bash_profile
            fi
        else
            echo PATH=/usr/local/bin:/usr/local/sbin:$PATH >> ~/.bash_profile
            source  ~/.bash_profile
        fi
    else

        print_status "Installing Homebrew"
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        if [ "$(grep ":/usr/local/sbin" ~/.bash_profile -q)" ]; then
            print_good "Paths are properly set"
        else
            print_status "Setting the path for homebrew"
            echo PATH=/usr/local/bin:/usr/local/sbin:$PATH >> ~/.bash_profile
            source  ~/.bash_profile
        fi
    fi
}

function install_ruby_rvm
{

    if [[ ! -e ~/.rvm/scripts/rvm ]]; then
        print_status "Installing RVM"

        bash < <(curl -sk https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer) >> $LOGFILE 2>&1
        PS1='$ '
        if [[ $OSTYPE =~ darwin ]]; then
            source ~/.bash_profile
        else
            source ~/.bashrc
        fi

        if [[ $OSTYPE =~ darwin ]]; then
            print_status "Installing Ruby"
            ~/.rvm/bin/rvm install 1.9.3 --autolibs=4 --verify-downloads 1 >> $LOGFILE 2>&1
        else
            ~/.rvm/bin/rvm install 1.9.3 --autolibs=4 --verify-downloads 1 >> $LOGFILE 2>&1
        fi

        if [[ $? -eq 0 ]]; then
            print_good "Installation of Ruby 1.9.3 was successful"

            ~/.rvm/bin/rvm use 1.9.3 --default >> $LOGFILE 2>&1
            print_status "Installing base gems"
            ~/.rvm/bin/rvm 1.9.3 do gem install bundler >> $LOGFILE 2>&1
            if [[ $? -eq 0 ]]; then
                print_good "Base gems in the RVM Ruby have been installed."
            else
                print_error "Base Gems for the RVM Ruby have failed!"
                exit 1
            fi
        else
            print_error "Was not able to install Ruby 1.9.3!"
            exit 1
        fi
    else
        print_status "RVM is already installed"
        if [[ "$( ls -1 ~/.rvm/rubies/)" =~ ruby-1.9.3-p... ]]; then
            print_status "Ruby for Cartero is already installed. Using ruby-1.9.3"
        else
            PS1='$ '
            if [[ $OSTYPE =~ darwin ]]; then
                source ~/.bash_profile
            else
                source ~/.bashrc
            fi

            print_status "Installing Ruby 1.9.3"
            ~/.rvm/bin/rvm install 1.9.3  --autolibs=4 --verify-downloads 1  >> $LOGFILE 2>&1
            if [[ $? -eq 0 ]]; then
                print_good "Installation of Ruby 1.9.3 was successful"

                ~/.rvm/bin/rvm use 1.9.3 --default >> $LOGFILE 2>&1
                print_status "Installing base gems"
                ~/.rvm/bin/rvm 1.9.3 do gem install bundler >> $LOGFILE 2>&1
                if [[ $? -eq 0 ]]; then
                    print_good "Base gems in the RVM Ruby have been installed."
                else
                    print_error "Base Gems for the RVM Ruby have failed!"
                    exit 1
                fi
            else
                print_error "Was not able to install Ruby 1.9.3!"
                exit 1
            fi
        fi
    fi
}

function install_ruby_osx
{
    print_status "Checking if Ruby 1.9.3 is installed, if not installing it."
    if [ -d /usr/local/Cellar/ruby193 ] && [ -L /usr/local/bin/ruby ]; then
        print_good "Correct version of Ruby is installed."
    else
        print_status "Installing Ruby 1.9.3"
        brew tap homebrew/versions >> $LOGFILE 2>&1
        brew install homebrew/versions/ruby193 >> $LOGFILE 2>&1
        echo PATH=/usr/local/opt/ruby193/bin:$PATH >> ~/.bash_profile
        source  ~/.bash_profile
    fi
    print_status "Installing the bundler Gem"
    gem install bundler >> $LOGFILE 2>&1
}

function install_mongodb {
	case $(uname -a) in
		*Darwin*)
			if [ -d /usr/local/Cellar/mongodb ] && [ -L /usr/local/bin/mongod ]; then
        print_good "Correct version of mongod is installed."
    	else
				print_status "Installing mongodb"
				brew install mongodb
			fi
			;;
		*Debian*)
			print_status "Installing mongodb"
			sudo apt-get install mongodb
			;;
		*Arch*)
			print_status "Installing mongodb"
			sudo pacman -Syu mongodb
			;;
		*)
			print_status "OS not supported. Install mongodb manually"
			;;
	esac	
}

function github_clone_cartero {
    git clone https://github.com/section9labs/Cartero /usr/local/share/Cartero >> $LOGFILE 2>&1    
}

NOW=$(date +"-%b-%d-%y-%H%M%S")
LOGFILE="/tmp/cartero-setup$NOW.log"

while getopts "r2:h" options; do
    case $options in
        r ) RVM=1;;
        \? ) usage
        exit 1;;
        * ) usage
        exit 1;;

    esac
done

print_status "Installing logs on $LOGFILE" 
# Check homebrew
if [[ $(uname -a) =~ Darwin ]]; then
	check_for_brew_osx
fi

# Check Mongodb
install_mongodb

# Installing Ruby RVM
if [[ $RVM -eq 1 ]]; then
    install_ruby_rvm
else
    install_ruby_osx
fi

print_status "Cloning Cartero from official Repository"
if [ -w /usr/local/share ]; then
    github_clone_cartero 
else
    sudo mkdir /usr/local/share/Cartero
    sudo chown -R `whoami` /usr/local/share/Cartero
    github_clone_cartero
fi    

cd /usr/local/share/Cartero

print_status "Installing dependencies" 
bundle install >> $LOGFILE 2>&1

print_status "Setting up cartero binary"
# Generate executable in PATH /usr/local/bin/cartero
if [ -w /usr/local/bin ]; then
sh -c 'echo "#!/bin/bash
/usr/local/share/Cartero/bin/cartero \$@" > /usr/local/bin/cartero'
chmod +x /usr/local/bin/cartero
else
    sudo sh -c 'echo "#!/bin/bash
/usr/local/share/Cartero/bin/cartero \$@" > /usr/local/bin/cartero'
    sudo chmod +x /usr/local/bin/cartero
fi

if [ -e /usr/loca/bin/cartero ]; then 
	print_good "Cartero command installed on /usr/local/bin/cartero"
fi

print_status "Setting default \$EDITOR to vim on ~/.bash_profile"
echo "# Setting EDITOR variable for Cartero Framework" >> ~/.bash_profile
print_error "IMPORTANT: Don't forget to source ~/.bash_profile"
