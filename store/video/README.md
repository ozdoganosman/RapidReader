# Tanıtım videosu (Remotion)

Play Store için dikey (1080x1920, 30 fps, ~30 sn) tanıtım videosunun kaynağı. Çıktı
`../tanitim-videosu.mp4` olarak repoda durur.

- `src/Promo.jsx`: sahneler, yazılar, animasyonlar ve sahne süreleri (`SCENES`)
- `public/clips/`: uygulamanın web sürümünden alınmış ekran kayıtları (720x1280)
- `public/fonts/`: Literata ve Roboto Mono (SIL OFL 1.1), Roboto (Apache 2.0)

```
npm install
npm run studio   # tarayıcıda önizleme ve düzenleme
npm run render   # out/tanitim-videosu.mp4
```

Remotion bireysel kullanımda ve en çok 3 kişilik şirketlerde ücretsizdir; daha büyük
bir şirket için lisans gerekir (remotion.dev/license).
