iReSignShell
=======
Command line support for iResign, GUI version please visit here https://github.com/maciekish/iReSign/
=======
use:
=======
$./iResignShell -h
options:
=======
    -h				display help
    -i <new BundleID>		new App ID
    -e <Entitlements.plist> 	Entitlements.plist
    -o <output file/path>		ipa out folder
    -s <cer_name>			cer name，like: iPhone Developer: xxxx
    -m <mobileprovision>		App ID 's mobileprovision
    Usage  examples : iResignShell [options] [-s cer_name] -m mobileprovision target.app(ipa)
#print help
=======
    iResignShell -h
#use cername + mobileprovision, output a resigned ipa to same folder as ipa,file name as "appname-resigned.ipa"
=======
    iResignShell -s "iPhone Distribution: SMARTMZ" -m My.mobileprovision My.ipa
#change Bundle ID to com.mai.App, and resign
=======
    iResignShell -i com.mai.App -c My_cer.p12 -p passwd -m My.mobileprovision My.ipa
#-o output ipa to a folder
=======
    iResignShell -s "iPhone Distribution: SMARTMZ" -m My.mobileprovision -o ~/ My.ipa
