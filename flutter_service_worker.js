'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"canvaskit/canvaskit.js": "66177750aff65a66cb07bb44b8c6422b",
"canvaskit/chromium/canvaskit.js": "671c6b4f8fcc199dcc551c7bb125f239",
"canvaskit/chromium/canvaskit.js.symbols": "a012ed99ccba193cf96bb2643003f6fc",
"canvaskit/chromium/canvaskit.wasm": "b1ac05b29c127d86df4bcfbf50dd902a",
"canvaskit/skwasm.js": "694fda5704053957c2594de355805228",
"canvaskit/canvaskit.js.symbols": "48c83a2ce573d9692e8d970e288d75f7",
"canvaskit/skwasm.wasm": "9f0c0c02b82a910d12ce0543ec130e60",
"canvaskit/skwasm.js.symbols": "262f4827a1317abb59d71d6c587a93e2",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"canvaskit/canvaskit.wasm": "1f237a213d7370cf95f443d896176460",
"flutter_bootstrap.js": "8c3ae80fd3dd9c281efbd263a81d731e",
"assets/NOTICES": "6b6acffdaba13bccd79758ec1c76a784",
"assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"assets/AssetManifest.bin": "ac70428fc6d7851ca1719343e51fe955",
"assets/assets/books.json": "00364bbcbd19a50d1f497acd6763ba2d",
"assets/assets/google_fonts/RobotoMono-Regular.ttf": "b8e9d3c6a9781435391cac5c650cf145",
"assets/assets/google_fonts/RobotoMono-Bold.ttf": "f0b322ac2a9e18ca6d07872fe7d84a30",
"assets/assets/google_fonts/OFL.txt": "e1a72ae9cb3ae2bc19cf4dea20623042",
"assets/assets/books/Kuran_78.txt": "c6bbe5e2d361eca4660fea1ad6292829",
"assets/assets/books/Kuran_40.txt": "1056fdddb475bcad1e1fb2a6bb72380d",
"assets/assets/books/ATTC_37.txt": "df8a3fc2c366fa3f2e3648484dc2d281",
"assets/assets/books/Kuran_43.txt": "0d2c25afc0a12aff558e0bc06525962c",
"assets/assets/books/ATTC_13.txt": "119a6cfa4ec1f2d06ef550347137bb73",
"assets/assets/books/Kuran_97.txt": "61c7b3addd1ac8d391692e5ebfa105a3",
"assets/assets/books/Kuran_77.txt": "bf5cb3f7d6b827b609d9f646c56c5dfb",
"assets/assets/books/ATTC_4.txt": "71d2495477f51ddf247538e4d635098a",
"assets/assets/books/Kuran_5.txt": "13a6e977441a7b78d8b1345e971c27c1",
"assets/assets/books/Kuran_1.txt": "ab3bb02585b6c5243c61aba89badf725",
"assets/assets/books/Kuran_86.txt": "f08539554b98ba43b2e8c3e1701b03d4",
"assets/assets/books/Kuran_33.txt": "e571abe23aa22a25facad58241101f8a",
"assets/assets/books/ATTC_43.txt": "38271b873b17bf643888da95f0255cc8",
"assets/assets/books/Kuran_82.txt": "5ac16aa76f4c42fd2fd29d4dde1bb12f",
"assets/assets/books/ATTC_22.txt": "d747a5c0cd74c395ffe7d566c00c3486",
"assets/assets/books/Kuran_103.txt": "d6aaf84038827bbee8a31891610dd995",
"assets/assets/books/Kuran_49.txt": "0609baa98b513e00d69e5531949511ad",
"assets/assets/books/ATTC_42.txt": "18907f9d7be35fcf735c0039cc7f1a5f",
"assets/assets/books/ATTC_32.txt": "593cf525d57ead1154ddd013fe28bcf7",
"assets/assets/books/Kuran_106.txt": "e56624e1968de6a1278385324ab8506b",
"assets/assets/books/Kuran_88.txt": "efa615f342c7143563696823f1b82a8b",
"assets/assets/books/Kuran_90.txt": "1dabd0d2d1375c778958faceb3d4929a",
"assets/assets/books/Kuran_83.txt": "8d66d729da98ac6dc2041664b2f4e816",
"assets/assets/books/Kuran_34.txt": "11077b7ff6a3fb9dd31701f3016644ff",
"assets/assets/books/Kuran_31.txt": "2cbd27bfcff3e85fdf2caa265f8b6738",
"assets/assets/books/ATTC_15.txt": "8c76e498b12fa40c6956e95f7a76524e",
"assets/assets/books/Kuran_3.txt": "eaa153b4082991ff598189618e14d9c8",
"assets/assets/books/ATTC_36.txt": "eda85dd07726ef3585008a82c5099361",
"assets/assets/books/Kuran_57.txt": "e9fff1e69aae158965c71d9ac7dd32b8",
"assets/assets/books/Kuran_53.txt": "5d98c1338a1d0a5cf187712871fffc23",
"assets/assets/books/ATTC_23.txt": "06366c7bacfa232eb6f382d003d18473",
"assets/assets/books/ATTC_2.png": "c19efdff6f61d9fa1e74b4fbe7a147c4",
"assets/assets/books/Kuran_39.txt": "4778c1603aa5b35edb949986345957c6",
"assets/assets/books/Kuran_105.txt": "c5e62b3d06babbf15f46195747303f47",
"assets/assets/books/ATTC_12.txt": "aa3771a97f7b6c5d92addb54dd44bae3",
"assets/assets/books/ATTC_20.txt": "0912c76b0dc65fa28b9efe34b7118e9e",
"assets/assets/books/Kuran_89.txt": "1738113523c2aec6cc01658bb50edba1",
"assets/assets/books/Kuran_69.txt": "efddea88a9ff3b9afe8c0bc50c7b14ca",
"assets/assets/books/Kuran_54.txt": "d4bae533cd8f21f4a62357f757e4b668",
"assets/assets/books/Kuran_80.txt": "aa52473e37a4b86551f7a26fd02c93c9",
"assets/assets/books/Kuran_8.txt": "84180049e88bc4446bc9f996a359a1a2",
"assets/assets/books/ATTC_25.txt": "ec9955a92daf0cc2d042411610981099",
"assets/assets/books/Kuran_96.txt": "9c9f7365427e725ba98b42d8e8e8a7a4",
"assets/assets/books/Kuran_111.txt": "b41c7af7a293e2898f32f00de163f666",
"assets/assets/books/ATTC_34.txt": "22f7c2c4876947d9c2ca4a67fd6dd548",
"assets/assets/books/Kuran_85.txt": "f6d97e356217bdc326d2de1d31ab2bc6",
"assets/assets/books/Kuran_108.txt": "2c9847f1f6d42c9de8ff1e72778787a6",
"assets/assets/books/Kuran_7.txt": "94906ee1109fa5da302af243e7892af0",
"assets/assets/books/Kuran_64.txt": "b41f0a6cbed6d72ed5a7d3e660fac052",
"assets/assets/books/Kuran_110.txt": "91154039840e485b6a2b805e8ac6f9e6",
"assets/assets/books/ATTC_31.txt": "d5b29bce69e935963e259d43d29de25e",
"assets/assets/books/ATTC_33.txt": "80919f6656544cc13d7ba53cefbe53c0",
"assets/assets/books/Kuran_20.txt": "b367aaf5d309fb2e769140252a8fb5a8",
"assets/assets/books/Kuran_71.txt": "5b2f3f6ac545948a55a1dd6c7f641128",
"assets/assets/books/ATTC_5.txt": "fd672c2a705abe679a9c7c3c82948c6c",
"assets/assets/books/Kuran_61.txt": "9b83b5cff988a6ca02b9e748adad4523",
"assets/assets/books/Kuran_45.txt": "70f234755946e84d9ef6799d74825c71",
"assets/assets/books/Kuran_10.txt": "74456372abe28543207a5ab0065d7049",
"assets/assets/books/Kuran_114.txt": "40f83ed96be8ab893e4ae86c03e0b575",
"assets/assets/books/Kuran_100.txt": "44f0295fc0c1cbfff55703ada92f47d5",
"assets/assets/books/Kuran_74.txt": "a8f7d186cf1c84a3728afc3b93bf6cdc",
"assets/assets/books/Kuran_26.txt": "86a87920480f34d1c00a971a27adbb74",
"assets/assets/books/Kuran_76.txt": "1357e60e3fda91c4c351f3d6a0521f47",
"assets/assets/books/Kuran_47.txt": "b70ecb66df29f90b22afc7ef09cacc72",
"assets/assets/books/ATTC.png": "467f00fef9fb608007fce92e050c221f",
"assets/assets/books/Kuran_15.txt": "69d707b9809067bef31545a646c24c93",
"assets/assets/books/Kuran_46.txt": "ea721bf0f329efc3302657febfdd6708",
"assets/assets/books/ATTC_40.txt": "731f06179d52084c23fbd73c20bd63b4",
"assets/assets/books/Kuran_68.txt": "b7af251f6d1da84d04fb54d927ee6e1d",
"assets/assets/books/Kuran_35.txt": "8a0c980973e6b950bd244c45e28d4f6b",
"assets/assets/books/Kuran_24.txt": "bd06e0bf594d7c5d90047d73e31ef0ef",
"assets/assets/books/Kuran_50.txt": "ebc82247d3877b098ba89625962b1e8d",
"assets/assets/books/Donusum.png": "96a1517dab7d00736ddaf5ea635d8bf2",
"assets/assets/books/ATTC_8.txt": "69ba6efa1afedeaa193e4f6f6709de03",
"assets/assets/books/Kuran_102.txt": "5d8936e898737169612185bba21d6320",
"assets/assets/books/Kuran_44.txt": "f426ca78aa3564444abcb64fbfbfa775",
"assets/assets/books/ATTC_44.txt": "e93dfb7eea7b33e47db419213c7b6a05",
"assets/assets/books/Kuran_12.txt": "8527b4e9585a80b837e221caff42d832",
"assets/assets/books/Kuran_92.txt": "cf0d37398d5f37632493858b1bc9315a",
"assets/assets/books/Kuran_98.txt": "39c2e406ebf15a7f9102dfba857c51dc",
"assets/assets/books/Kuran_25.txt": "3d2a8c9373a1d7fba2300548c2efa437",
"assets/assets/books/Donusum_2.txt": "6b18d2fafc0d88edd99a98fb26d88d57",
"assets/assets/books/Kuran_91.txt": "d77050a0e88f5ddfd516aebc82acf18d",
"assets/assets/books/Kuran_14.txt": "5c19afd2e43484f87f8106c17ce2f611",
"assets/assets/books/ATTC_27.txt": "a13dcb17ad8010ef76af28644ddd7bae",
"assets/assets/books/Kuran_67.txt": "a714777d328fa233d6881ed3d74c3e04",
"assets/assets/books/Donusum_2.png": "8b38590256a466123c405fe5e73302c3",
"assets/assets/books/Kuran_58.txt": "28459ca0c9ffcab0b29a280d00235e73",
"assets/assets/books/Kuran_41.txt": "07e218514b579bdf048d825e4af66a23",
"assets/assets/books/Kuran_107.txt": "da097f7f8e9e93a8971f4a46cb6fbebd",
"assets/assets/books/Kuran_42.txt": "4ea13f6c7a02015139b60fc9819f600e",
"assets/assets/books/ATTC_7.txt": "bc98c2e1c4c421ba0d0c8090057316f3",
"assets/assets/books/Kuran_38.txt": "776c90ee1e9f2e38a40de4d9f2e9b98d",
"assets/assets/books/ATTC_41.txt": "8708af133e7316385f313a9bfdafe8c0",
"assets/assets/books/ATTC_3.txt": "3b21238b8691be8cc4326b0941b459e7",
"assets/assets/books/Kuran_9.txt": "4dbfceef51ef3b638bbcb1eae5e4fb7b",
"assets/assets/books/ATTC_14.txt": "58398aa14061a62bad9b01c1ba8e472a",
"assets/assets/books/Kuran_104.txt": "da5eb4290c7563422263d926b95464b6",
"assets/assets/books/ATTC_9.txt": "193c9815e395ee6d5ab62559ca63fa59",
"assets/assets/books/Kuran_11.txt": "fa9a81829f6afd200b4fc3ac0e3fde7a",
"assets/assets/books/Kuran_99.txt": "abc3e63b127d36988a70c2068f108f89",
"assets/assets/books/ATTC_28.txt": "387e5d7d818c38a60865ff009bb46116",
"assets/assets/books/Kuran_23.txt": "daf4f5ce19268de4ff15d6b327c7c883",
"assets/assets/books/Kuran_113.txt": "37fa88c440ab74c758acf94c33bb1e9e",
"assets/assets/books/Kuran_84.txt": "8b07881cefec96558a7812ebf7a7551a",
"assets/assets/books/ATTC_39.txt": "22589fd5ed77dc6d061d12e6ba35173f",
"assets/assets/books/Kuran_62.txt": "020fc2455562bd5ab56f1b1322c6922c",
"assets/assets/books/Kuran_73.txt": "75b9e4ee01c58912d3b5e27c611bc370",
"assets/assets/books/ATTC_2.txt": "3458b13cdbda18871d9db4df2f2b3ab4",
"assets/assets/books/Kuran_32.txt": "169895818ce05050d5a05e9ad748a51a",
"assets/assets/books/Kuran_17.txt": "a2f9305cb064f3c6bef120fc0aaa919b",
"assets/assets/books/Kuran_4.txt": "85b4098e346d4ea74c2283b094c4982e",
"assets/assets/books/Kuran_52.txt": "608d30d8e3befb5b2e0724a8f1dd477c",
"assets/assets/books/Kuran_109.txt": "3ef951e0512bce835d8667a2affcdece",
"assets/assets/books/Kuran_2.txt": "d52ae68eefc1051e93e0960e2a45e4af",
"assets/assets/books/ATTC_35.txt": "cd812e8db3c4d4f9d593f3144faed28f",
"assets/assets/books/ATTC_45.txt": "ef3773089ffdffb5f5a2c477b37a8c66",
"assets/assets/books/Kuran_101.txt": "dff466bb9432b0f871383a4f903f22a9",
"assets/assets/books/Kuran_59.txt": "91c99824f7731243f7080ac1dc1bd734",
"assets/assets/books/Kuran_66.txt": "33558fcd188afedfbfd9317c2065bc92",
"assets/assets/books/ATTC_18.txt": "6a40376e182a144da4be12dbad965ea0",
"assets/assets/books/Donusum_3.txt": "55133ca5d1a05c3097e850a347b3edec",
"assets/assets/books/Kuran_27.txt": "83cfe5a0f69f57485223622188c330c8",
"assets/assets/books/Kuran_87.txt": "59e12eb7ca04c2b13283a6ef453d4a86",
"assets/assets/books/ATTC_10.txt": "4349a63f75321050c46149c6dab715d2",
"assets/assets/books/ATTC_26.txt": "5940f3537f997a9af5017e061a7d071c",
"assets/assets/books/Kuran_93.txt": "b4ba643c8f6c8ea4bbaadb53365f8169",
"assets/assets/books/ATTC_24.txt": "506e25ef0a6e4fbed7aed6e016d7e42d",
"assets/assets/books/Kuran_18.txt": "c5c66382df14fb15c4c986d48787ab59",
"assets/assets/books/Donusum_1.png": "a7c34cd87417af42898309b08876fc8c",
"assets/assets/books/Donusum_3.png": "2f7a1abbb7ceecbb91cc59ba299ee125",
"assets/assets/books/Kuran_37.txt": "f499025d7b0f655e7cc94c2037823593",
"assets/assets/books/ATTC_17.txt": "8053804f9cad163b41163c662221227d",
"assets/assets/books/Kuran_79.txt": "96d7f93cb3f462792cec735c2412ffff",
"assets/assets/books/Kuran_28.txt": "01e1c2892368025e2368446ced332d2a",
"assets/assets/books/Kuran_95.txt": "7fe18f5f442441cb28ecaf887e34cc19",
"assets/assets/books/Kuran_65.txt": "0758b2c2ed927f9f95e1d95c9e7400d6",
"assets/assets/books/ATTC_38.txt": "9730beb662676a354a4d89f167278ea1",
"assets/assets/books/Kuran_22.txt": "c07a45b244cacf5ebf7583e7cc2fa084",
"assets/assets/books/Kuran_16.txt": "5458eb9e8326c07e83c2d7c026890f11",
"assets/assets/books/ATTC_11.txt": "3a94c126d55ade0d0781bdd443a11944",
"assets/assets/books/Kuran_94.txt": "00e13db6a330af185731ce238031d46f",
"assets/assets/books/Kuran_55.txt": "47b77d6d0d0cd83d349f1cee350893e6",
"assets/assets/books/ATTC_1.txt": "8962efb4106001f4a5e6bf09c5d46bb4",
"assets/assets/books/Kuran_75.txt": "3d830b97d17501261af042a06d33c00d",
"assets/assets/books/Kuran_60.txt": "92c3cfec354b2f9819afd5dde750eb15",
"assets/assets/books/ATTC_21.txt": "a7fc09a69e2595f24a8fed3dbefaf6fe",
"assets/assets/books/Kuran_70.txt": "81af4471b66e757f6a48b24f56a3be7b",
"assets/assets/books/ATTC_6.txt": "6000307de87cf6b591074fa78748376d",
"assets/assets/books/Kuran_6.txt": "ddcc515c35eee20406d94bd28753fca3",
"assets/assets/books/Kuran_19.txt": "a8c551383df781f78362fa6b4cf922db",
"assets/assets/books/ATTC_16.txt": "3b01df7489e1354e9063fb4122926314",
"assets/assets/books/ATTC_29.txt": "d816339ac71f5e97c25d689a59aa81e0",
"assets/assets/books/ATTC_19.txt": "06ba7cdb94241e7307095e1795bbf98a",
"assets/assets/books/Kuran_51.txt": "7fd7a2a0fc74ee569aa2307d0d6a0011",
"assets/assets/books/Donusum_1.txt": "6eaa867be35ae6b86c2ab966af943f7b",
"assets/assets/books/Kuran_21.txt": "49b81a3eee3367a8ace1dbc44befe7b9",
"assets/assets/books/Kuran_48.txt": "fd489794253021b5b7ffc2ebb35aee3a",
"assets/assets/books/ATTC_1.png": "6dafda7b12d1c717b6d50a425bb9d8bf",
"assets/assets/books/ATTC_30.txt": "4a5a9d12ebdf7ed63964ca273fded2c5",
"assets/assets/books/Kuran_13.txt": "5197807130855c89067ee030221f3a4c",
"assets/assets/books/Kuran_72.txt": "3b15ad0ee8614c1fd56d532fe5dee096",
"assets/assets/books/Kuran_29.txt": "097e9c7909a40f9a4ed4b2fb6c65655e",
"assets/assets/books/Kuran_30.txt": "0a5afb93b3596f2b69f1fe714c10ecd7",
"assets/assets/books/Kuran_63.txt": "4cf04faa89b1cae60396dfdec01312ec",
"assets/assets/books/Kuran_81.txt": "6dea6a6b99951b07844fd83402c4ac1c",
"assets/assets/books/Kuran_112.txt": "66c8642756cc7e4753ee78d24ea23e09",
"assets/assets/books/Kuran_56.txt": "0601a3545f99bb12e8d47141fecc450a",
"assets/assets/books/Kuran_36.txt": "edb9ec8e81ea788263983a50fd3a8e59",
"assets/FontManifest.json": "7b2a36307916a9721811788013e65289",
"assets/AssetManifest.json": "ad2abca9c16f0a60b687b539959d0dd1",
"assets/fonts/MaterialIcons-Regular.otf": "9befdb0e2a418d14a694e93f205827d6",
"assets/AssetManifest.bin.json": "460e90974bf490917a8d1f179e08b0df",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"index.html": "7a3937b148fde6fef56070de1be4bb72",
"/": "7a3937b148fde6fef56070de1be4bb72",
"flutter.js": "f393d3c16b631f36852323de8e583132",
"main.dart.js": "eaa00cadfa6a86af61fd486138ba6bf1",
"manifest.json": "1def732f0cdd34b65c86f8f26ca982d8",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"version.json": "98287878d9a76296444af262f9fe57eb"};
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
