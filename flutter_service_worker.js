'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "9037a93fd333731b968506daeda372bf",
".git/config": "65e0798b1fd20ef8f28f730186629934",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "4cf2d64e44205fe628ddd534e1151b58",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "a8779c1cfa03d5d5e5fcdbd6750ccd12",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "114c141ff3a966e9b6ac67177e2c5fdf",
".git/logs/refs/heads/master": "114c141ff3a966e9b6ac67177e2c5fdf",
".git/objects/3e/aada65ca43c732cd691b70ed3a147cd08a32d9": "c761604a29648ab0c1873146cc217029",
".git/objects/bc/2afff9cac4b77b33691d42a41d33afb4970e08": "6253050684f68979975e37d392c00f89",
".git/objects/f5/b7286b3efb9adccd7e9a17f781ffa159fb74f7": "7e8ad5caf15abd2e4e658b11790b185f",
".git/refs/heads/master": "867573efea7dc74c4ad7c8463bb3dbf3",
"assets/AssetManifest.bin": "51c40f73ddec179e846d662fee30d525",
"assets/AssetManifest.bin.json": "f5dca89d788ce645e97ef8e5b6bf4959",
"assets/AssetManifest.json": "9c8483abb4f82dd122ee5496743d5c2f",
"assets/assets/books/ATTC.png": "467f00fef9fb608007fce92e050c221f",
"assets/assets/books/ATTC_1.png": "6dafda7b12d1c717b6d50a425bb9d8bf",
"assets/assets/books/ATTC_1.txt": "4bf34e38a0a7588d9cacf05c86c559aa",
"assets/assets/books/ATTC_10.txt": "0644b326e4ba654076b9c56a1dc97eda",
"assets/assets/books/ATTC_11.txt": "f6f6e7c0a8b9fb6a750c68b05bebc28a",
"assets/assets/books/ATTC_12.txt": "7282df3e45bcd2aeb80797873769f466",
"assets/assets/books/ATTC_13.txt": "ab35f3f6d6dab09963093ba98aeb26e7",
"assets/assets/books/ATTC_14.txt": "6f1508d1a01b65115a4ed5dc83235b4a",
"assets/assets/books/ATTC_15.txt": "026c77280964430ecefac88d7c419f81",
"assets/assets/books/ATTC_16.txt": "7d854b4d808453ae7635b10373e5c399",
"assets/assets/books/ATTC_17.txt": "46f90f1c4d1818ab11e45fb3d33b6a41",
"assets/assets/books/ATTC_18.txt": "501e273f042543fa80e5226d79d5bdab",
"assets/assets/books/ATTC_19.txt": "93e41e11fb688e926f6efd6f86cd65c2",
"assets/assets/books/ATTC_2.png": "c19efdff6f61d9fa1e74b4fbe7a147c4",
"assets/assets/books/ATTC_2.txt": "5f4b63a87b2f206cc06256d142c9bc01",
"assets/assets/books/ATTC_20.txt": "ffd4e7b70b9cf6c1c8dccd9d97bceac9",
"assets/assets/books/ATTC_21.txt": "93be9f71a05aa67d0ac1019386a3095a",
"assets/assets/books/ATTC_22.txt": "4357a7ab7ad588eeadfe9ddb72f57436",
"assets/assets/books/ATTC_23.txt": "ea2de2d4bf325d29b6f44dfd54b0f2b1",
"assets/assets/books/ATTC_24.txt": "0fe90061405517c3cdceb068e4cd7d18",
"assets/assets/books/ATTC_25.txt": "9e8c529c0761fd528f336703b34cf0bf",
"assets/assets/books/ATTC_26.txt": "0374d05d7a3ce8844f4938d247eed949",
"assets/assets/books/ATTC_27.txt": "33d432efdeb261dca7710d9f2779c20b",
"assets/assets/books/ATTC_28.txt": "46261e87de07a7e0b70a7acdcff855fd",
"assets/assets/books/ATTC_29.txt": "a487193a4c9743e99f8ca83822855b1b",
"assets/assets/books/ATTC_3.txt": "4647fcb242761f86292b08615815380e",
"assets/assets/books/ATTC_30.txt": "d83e449af8c0a661820fb63a5ccfbf92",
"assets/assets/books/ATTC_31.txt": "d23f5e0679c25a19c476324f9cfd6fa8",
"assets/assets/books/ATTC_32.txt": "4987f828e22a3e1a5c91253b5de4af42",
"assets/assets/books/ATTC_33.txt": "e10de445a7c4daa3f03fceb7a8ad737e",
"assets/assets/books/ATTC_34.txt": "3e439e4f22db7750661f708792e17d89",
"assets/assets/books/ATTC_35.txt": "afa564a4b01e9b407bf5d0f8e6d2440c",
"assets/assets/books/ATTC_36.txt": "9324edf3145a323498d27fd71ba74efd",
"assets/assets/books/ATTC_37.txt": "f53839dfb7ec6ee14a2f2e70d0ea5f47",
"assets/assets/books/ATTC_38.txt": "77a89b969b8dbf0751252ad8e78e73d5",
"assets/assets/books/ATTC_39.txt": "0be72fcb2594237ca9708b402b81f2b3",
"assets/assets/books/ATTC_4.txt": "e0de14287cf1c7c0b48e66c4ec8db1e3",
"assets/assets/books/ATTC_40.txt": "5d1e53e688e4d48eb198162ef78b2a1e",
"assets/assets/books/ATTC_41.txt": "72265231500bcc6551d1275dc7fa60f2",
"assets/assets/books/ATTC_42.txt": "ab860f4d9bb9c1f46baf26fe99a65000",
"assets/assets/books/ATTC_43.txt": "ba2170d0af6578a2927fe5986ecbb4ca",
"assets/assets/books/ATTC_44.txt": "9a5d3041d804a894e92bcfb3914b95b3",
"assets/assets/books/ATTC_45.txt": "97d4d9d905975cec8a625674644ed255",
"assets/assets/books/ATTC_5.txt": "79fb099ce389325ef5576e1ddac16bce",
"assets/assets/books/ATTC_6.txt": "92e23359a878a92a12083376674b2b60",
"assets/assets/books/ATTC_7.txt": "e98f4b2e4c4b02db274db416364f1c03",
"assets/assets/books/ATTC_8.txt": "14427998d5a6b2da73e83b03fc4a2b84",
"assets/assets/books/ATTC_9.txt": "5d1903a010833016a466ac972cd3ec4e",
"assets/assets/books/Donusum.png": "96a1517dab7d00736ddaf5ea635d8bf2",
"assets/assets/books/Donusum_1.png": "a7c34cd87417af42898309b08876fc8c",
"assets/assets/books/Donusum_1.txt": "57e8fd610079669856976ebf8c4e3464",
"assets/assets/books/Donusum_2.png": "8b38590256a466123c405fe5e73302c3",
"assets/assets/books/Donusum_2.txt": "b5d485a939b042e5a1d0661094d0a094",
"assets/assets/books/Donusum_3.png": "2f7a1abbb7ceecbb91cc59ba299ee125",
"assets/assets/books/Donusum_3.txt": "bfc89c7a4d69bb30dd00647ec8869bbb",
"assets/assets/books/Kuran_1.txt": "1f38c771f146724726671cb51e59eddd",
"assets/assets/books/Kuran_10.txt": "f743065969c3387bbf0e8467369b5b1e",
"assets/assets/books/Kuran_100.txt": "8fbe82d7dd93e1fab2e601eea1c56b16",
"assets/assets/books/Kuran_101.txt": "16e3a117114b4875ebb1f66a36517189",
"assets/assets/books/Kuran_102.txt": "a1db11a60af20593ea1f3b9642b1cd0b",
"assets/assets/books/Kuran_103.txt": "abcf54ae646785922706a54902c4417d",
"assets/assets/books/Kuran_104.txt": "f060be6f713d2099a6c44d4db81673d9",
"assets/assets/books/Kuran_105.txt": "177d4adaca399a3d032d32c69993e5af",
"assets/assets/books/Kuran_106.txt": "b4d2b183f9298926ebcfb3fb15e8b665",
"assets/assets/books/Kuran_107.txt": "0cee498d803982b17afa92524dec7a9f",
"assets/assets/books/Kuran_108.txt": "c086d387fdda99d85789c78227fa1a23",
"assets/assets/books/Kuran_109.txt": "844e75dbfab1e4e7309335e369d87467",
"assets/assets/books/Kuran_11.txt": "7daced123f235190f66eaa4f96fba9cf",
"assets/assets/books/Kuran_110.txt": "dfd6856d9c4fc493a2eeb7eeb28bf230",
"assets/assets/books/Kuran_111.txt": "ac9c9667a9fa543dc1b955e5ee98234e",
"assets/assets/books/Kuran_112.txt": "107202dd50e348c8327d8482b22728b9",
"assets/assets/books/Kuran_113.txt": "0362b6b750a3253766ddebe12dc6da4e",
"assets/assets/books/Kuran_114.txt": "49aed6fc21e03a25c92b54403d0af875",
"assets/assets/books/Kuran_12.txt": "0c32478e735bdf4f79e2604ceffc7105",
"assets/assets/books/Kuran_13.txt": "cdc219e83cd029b75952d289f279f333",
"assets/assets/books/Kuran_14.txt": "532890e80280764451965ee60aa0422d",
"assets/assets/books/Kuran_15.txt": "0c2321974b6731e6e1dce70240c763f5",
"assets/assets/books/Kuran_16.txt": "9899767fbc6c92f0093af75bfcee49c1",
"assets/assets/books/Kuran_17.txt": "f28c814eee982b20f1220e6fe5928f2b",
"assets/assets/books/Kuran_18.txt": "76729ce2f2dbda845473d1829673777f",
"assets/assets/books/Kuran_19.txt": "9fd58c103bcdfdffddbfb07ff43078f7",
"assets/assets/books/Kuran_2.txt": "7a95bfb8923f039b53f0268519670f0c",
"assets/assets/books/Kuran_20.txt": "cb0a68f2099e87d3aeb1c80b02b29417",
"assets/assets/books/Kuran_21.txt": "10c50a590b2f0e21c17c753d1461a705",
"assets/assets/books/Kuran_22.txt": "a7d2849b91294c8f15ab718cfd9fc546",
"assets/assets/books/Kuran_23.txt": "65f963f89108d83fd4020bbf0e40e8df",
"assets/assets/books/Kuran_24.txt": "880b8fa1bc205a68a8c23dafb75556bc",
"assets/assets/books/Kuran_25.txt": "5dc9e2be0f3d8cc065bb072d1db114e5",
"assets/assets/books/Kuran_26.txt": "ced1fbfd326fe9873b6c4cb75889fae3",
"assets/assets/books/Kuran_27.txt": "2b6541c398d60702262aaf4cec91c82a",
"assets/assets/books/Kuran_28.txt": "23ee7c7d31a5effdeee8ab826bff59aa",
"assets/assets/books/Kuran_29.txt": "f7e9dd57ee8a7724e3c5115068d4516d",
"assets/assets/books/Kuran_3.txt": "5766150753427a4bcd1f425c62ea170a",
"assets/assets/books/Kuran_30.txt": "bb46e1c60b67171d3d983c24b469c117",
"assets/assets/books/Kuran_31.txt": "ecd2adc08a738b4a19f138d783000d72",
"assets/assets/books/Kuran_32.txt": "e2e0a41e354a04c52178f4fde1f13223",
"assets/assets/books/Kuran_33.txt": "3c7203e866c3e0c382815363e795f639",
"assets/assets/books/Kuran_34.txt": "2fb273ee7106cc72c651004b8626d607",
"assets/assets/books/Kuran_35.txt": "c115ae9575c8837f7c59f1333944009c",
"assets/assets/books/Kuran_36.txt": "9107a682b8c620dc782e6d669772f40a",
"assets/assets/books/Kuran_37.txt": "d8f68a0ba18ffc48388766281d789063",
"assets/assets/books/Kuran_38.txt": "6201cac070bc645bc4f5f24ebd4601c4",
"assets/assets/books/Kuran_39.txt": "03180cf4304bb05dd2bf0d24c9b86256",
"assets/assets/books/Kuran_4.txt": "4bd4baf91f17e8fa9ea7ec01e4eed630",
"assets/assets/books/Kuran_40.txt": "2133d802e9693ff80a227962db9d3b13",
"assets/assets/books/Kuran_41.txt": "0841c04577bd95f5ab098c79d36bd120",
"assets/assets/books/Kuran_42.txt": "424ceaf70644bedb453eeaae973922b3",
"assets/assets/books/Kuran_43.txt": "67772ec6bb7fd1821f32128804a93ac8",
"assets/assets/books/Kuran_44.txt": "e9829b999954854893b296e45e900fdd",
"assets/assets/books/Kuran_45.txt": "00de60d2e8fb7205af34be4fe12f94af",
"assets/assets/books/Kuran_46.txt": "6a1affd45f962d8a687089b78d8bd329",
"assets/assets/books/Kuran_47.txt": "c1fa900130d9f031f157af6446d4521a",
"assets/assets/books/Kuran_48.txt": "eb73019bb776f7f5d878e9fe29f9354f",
"assets/assets/books/Kuran_49.txt": "2e52ce69529c15a523fa1a9a60fa31a5",
"assets/assets/books/Kuran_5.txt": "ef615403778ec6e5f2ff6eda7d2f3813",
"assets/assets/books/Kuran_50.txt": "5593070f0c573dcf4345e72cfa3a0221",
"assets/assets/books/Kuran_51.txt": "8e45b7fb23da3478a81cdd2d8a7add09",
"assets/assets/books/Kuran_52.txt": "11606c2e04edb2b1c392ed97c863ed9c",
"assets/assets/books/Kuran_53.txt": "8ffa256ffcf930306531757e6e8a0a86",
"assets/assets/books/Kuran_54.txt": "f2e27cb666f45fd89756974787824ae3",
"assets/assets/books/Kuran_55.txt": "13a39e6ec490fd99723c12c1a2445cfa",
"assets/assets/books/Kuran_56.txt": "c3b3c13baa2895f20d3166a570d0ddf8",
"assets/assets/books/Kuran_57.txt": "9b5649a957cc6b27bc9d7135411af726",
"assets/assets/books/Kuran_58.txt": "02f1479a386e0f3726feacb0540bbfef",
"assets/assets/books/Kuran_59.txt": "a6795a3dbf553933c6d50b01ab42d921",
"assets/assets/books/Kuran_6.txt": "4153acd32d1e7f5510a5f553fa28f83a",
"assets/assets/books/Kuran_60.txt": "8826752c27330d182e693019df247a89",
"assets/assets/books/Kuran_61.txt": "cd734a5459f8aca366915194635a49f4",
"assets/assets/books/Kuran_62.txt": "62436737973a24c66e8b84b47dc61c45",
"assets/assets/books/Kuran_63.txt": "2cb6f070444fe4628a97c833da2d6488",
"assets/assets/books/Kuran_64.txt": "2761a7b77f095e407b40fffd65857fe8",
"assets/assets/books/Kuran_65.txt": "43121118531c7e7260095e053164765d",
"assets/assets/books/Kuran_66.txt": "aae1c29c3e69f0bc32b4533c2487790a",
"assets/assets/books/Kuran_67.txt": "1994ecde8b4529854e7a501dd8ffb071",
"assets/assets/books/Kuran_68.txt": "ed7d1a40e4c0c8f9cd99d23ecc86f489",
"assets/assets/books/Kuran_69.txt": "3237fb1fec392c30e7277ef45db4b365",
"assets/assets/books/Kuran_7.txt": "2f73e5953c40bac8447e7df637877e88",
"assets/assets/books/Kuran_70.txt": "24e9f84a329fe96c092ce8005239c00a",
"assets/assets/books/Kuran_71.txt": "501732534495e9503a1c2f7a8f733904",
"assets/assets/books/Kuran_72.txt": "cadda6d780424749b7ce044df499b7bf",
"assets/assets/books/Kuran_73.txt": "070bdc90f6772df9a583d4782ec7c55a",
"assets/assets/books/Kuran_74.txt": "8158525c704c95d8b795f92bd28ad827",
"assets/assets/books/Kuran_75.txt": "3cc38150585486a1b60e48183ce4f68a",
"assets/assets/books/Kuran_76.txt": "763f654eebafbaac17043fbeb77756d0",
"assets/assets/books/Kuran_77.txt": "c098ebb4b587d41b1d994076e8878b4d",
"assets/assets/books/Kuran_78.txt": "bab9e3c133fb88ab6353ff1e7c4d44ae",
"assets/assets/books/Kuran_79.txt": "8550c47b9a15bfd85f86d0fb21bbb33d",
"assets/assets/books/Kuran_8.txt": "6700933815bec8b183414c2c4d8158e9",
"assets/assets/books/Kuran_80.txt": "229df46b5a26198a9156bdd5c9ddebc8",
"assets/assets/books/Kuran_81.txt": "d693f67741f6ad1a9ba0c54cb106f12f",
"assets/assets/books/Kuran_82.txt": "9cd6623dd2b2171342fad2cba01370ef",
"assets/assets/books/Kuran_83.txt": "1636d39b2abb1a978990e7697edfc467",
"assets/assets/books/Kuran_84.txt": "a971029a0a6fb81c6a48c76ae4a812b8",
"assets/assets/books/Kuran_85.txt": "4b23d84af19a747d624c5e2f1289d910",
"assets/assets/books/Kuran_86.txt": "9b9a4b7eeb4dd3077b3c4d213522a22d",
"assets/assets/books/Kuran_87.txt": "912abd5a51ca62446c9c82bc758db4fe",
"assets/assets/books/Kuran_88.txt": "2166375d875bdea1b86404884e343d75",
"assets/assets/books/Kuran_89.txt": "891b6c1bc4cc9e95aa8346d7d9be9b7a",
"assets/assets/books/Kuran_9.txt": "e4792a9528279a5c08e2bbe0fff5ba41",
"assets/assets/books/Kuran_90.txt": "c8ad98008cf1db579f3ccbbacf0fd50c",
"assets/assets/books/Kuran_91.txt": "dcdd65c4b159afe9b3584b743a59ebd8",
"assets/assets/books/Kuran_92.txt": "96c2e4ec7cdfdd3227b6fe4fd001feaa",
"assets/assets/books/Kuran_93.txt": "0f9c4a2020b03314aa2f4c85a49fe430",
"assets/assets/books/Kuran_94.txt": "ac8c71ef23a090ef0ee3ae0b96a943d5",
"assets/assets/books/Kuran_95.txt": "727863843d60e759d3dd1a898c117955",
"assets/assets/books/Kuran_96.txt": "ae4e64567d1974d5304f7e3d27f07af5",
"assets/assets/books/Kuran_97.txt": "a5e92679b6c833a14039502ceadda86b",
"assets/assets/books/Kuran_98.txt": "3404c148f532e313db90f199c9619b7f",
"assets/assets/books/Kuran_99.txt": "44ad16adc634bdb7e6525933e2303292",
"assets/assets/books.json": "00364bbcbd19a50d1f497acd6763ba2d",
"assets/FontManifest.json": "7b2a36307916a9721811788013e65289",
"assets/fonts/MaterialIcons-Regular.otf": "9befdb0e2a418d14a694e93f205827d6",
"assets/NOTICES": "cb3566bb8af4eecb3d5403fb846805f5",
"assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "66177750aff65a66cb07bb44b8c6422b",
"canvaskit/canvaskit.js.symbols": "48c83a2ce573d9692e8d970e288d75f7",
"canvaskit/canvaskit.wasm": "1f237a213d7370cf95f443d896176460",
"canvaskit/chromium/canvaskit.js": "671c6b4f8fcc199dcc551c7bb125f239",
"canvaskit/chromium/canvaskit.js.symbols": "a012ed99ccba193cf96bb2643003f6fc",
"canvaskit/chromium/canvaskit.wasm": "b1ac05b29c127d86df4bcfbf50dd902a",
"canvaskit/skwasm.js": "694fda5704053957c2594de355805228",
"canvaskit/skwasm.js.symbols": "262f4827a1317abb59d71d6c587a93e2",
"canvaskit/skwasm.wasm": "9f0c0c02b82a910d12ce0543ec130e60",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "f393d3c16b631f36852323de8e583132",
"flutter_bootstrap.js": "10e2d573deb58439e3f9874184166123",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "16555ff09de878feccdaef80a5d063ae",
"/": "16555ff09de878feccdaef80a5d063ae",
"main.dart.js": "a86a3d86009a307393973e78bb2a2ffc",
"manifest.json": "a6357da0ce8774365a2f78231bb78b17",
"privacy-policy.html": "ee4db532a118a87b9edcbdc0e03ddad1",
"version.json": "e418fdb55d0fd6371bebd29a2b866806"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
