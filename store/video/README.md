# Tanıtım videosu (Remotion)

Play Store için dikey (1080x1920, 30 fps, ~30 sn) tanıtım videolarının kaynağı: Türkçe
(`Tanitim` → `../tanitim-videosu.mp4`) ve İngilizce (`Promo` → `../promo-video-en.mp4`).

- `src/Promo.jsx`: sahneler, animasyonlar, sahne süreleri (`SCENES`) ve iki dilin yazıları (`TEXT`)
- `public/clips/` ve `public/clips/en/`: uygulamanın web sürümünden alınmış Türkçe ve İngilizce
  ekran kayıtları (720x1280)
- `public/fonts/`: Literata ve Roboto Mono (SIL OFL 1.1), Roboto (Apache 2.0)

```
npm install
npm run studio   # tarayıcıda önizleme ve düzenleme
npm run render      # out/tanitim-videosu.mp4
npm run render:en   # out/promo-video-en.mp4
```

Remotion bireysel kullanımda ve en çok 3 kişilik şirketlerde ücretsizdir; daha büyük
bir şirket için lisans gerekir (remotion.dev/license).
