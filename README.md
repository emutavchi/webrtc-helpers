Build dependencies on Ubuntu 16.04:

<pre>
$ sudo apt-get install libexpat-dev libjsoncpp-dev libevent-dev gyp ninja-build quilt git libssl-dev libasound2-dev autotools-dev libtool automake autoconf pkg-config libvpx-dev
</pre>

Also build and install usrsctp:

<pre>
cd ~
git clone https://github.com/sctplab/usrsctp.git
cd usrsctp
git checkout 0.9.3.0
./bootstrap && ./configure --prefix=/usr --disable-inet --disable-inet6 --disable-debug --disable-warnings-as-errors
make
sudo make install
</pre>
