airootfs=(airootfs/etc)

#grub
mkdir -p  "$airootfs/default"
cp -r "/etc/default/grub" "$airootfs/default"

#os-release
cp -r "/usr/lib/os-release" $airootfs
sed -i 's/NAME="arch Linux"/NAME="VoidPunk"/' $airootfs/os-release

# wheel Group
mkdir -p "airootfs/sudoers.d"
g_wheel=($airootfs/sudoers.d/g_wheel)
echo "%wheel ALL=(ALL:ALL) ALL" > $g_wheel

