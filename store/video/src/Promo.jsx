// RapidReader tanıtım videosu: dikey (1080x1920), 30 fps. Uygulama
// görüntüleri public/clips altındaki ekran kayıtlarıdır (web sürümü).
import React from 'react';
import { loadFont } from '@remotion/fonts';
import { linearTiming, TransitionSeries } from '@remotion/transitions';
import { fade } from '@remotion/transitions/fade';
import { AbsoluteFill, Img, interpolate, OffthreadVideo, spring, staticFile, useCurrentFrame, useVideoConfig } from 'remotion';

loadFont({ family: 'Literata', url: staticFile('fonts/Literata-Bold.ttf'), weight: '700' });
loadFont({ family: 'Roboto', url: staticFile('fonts/Roboto-Regular.ttf'), weight: '400' });
loadFont({ family: 'Roboto', url: staticFile('fonts/Roboto-Medium.ttf'), weight: '500' });
loadFont({ family: 'Roboto Mono', url: staticFile('fonts/RobotoMono-Bold.ttf'), weight: '700' });

const RED = '#FF5252';
const BG = '#121212';
const GREY = '#BDBDBD';
const FADE = 15;

// Scene lengths in frames; the clips are a little longer (their last
// frame is held)
const SCENES = { intro: 135, speed: 234, modes: 114, guided: 198, listen: 216, home: 144, outro: 150 };
export const PROMO_FRAMES = Object.values(SCENES).reduce((a, b) => a + b, 0) - FADE * (Object.keys(SCENES).length - 1);

const background = {
  backgroundColor: BG,
  backgroundImage: 'radial-gradient(circle at 50% 68%, rgba(255,82,82,0.10) 0%, rgba(18,18,18,0) 50%)',
};

const useSpring = (delay, config = { damping: 200 }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  return spring({ frame: frame - delay, fps, config });
};

/// Words that rise in one after another; [word, true] is red, ['\n'] a
/// line break
const Words = ({ words, delay = 0, style }) => (
  <div style={style}>
    {words.map(([word, accent], i) =>
      word === '\n' ? <br key={i} /> : <Word key={i} word={word} accent={accent} delay={delay + i * 4} />,
    )}
  </div>
);

const Word = ({ word, accent, delay }) => {
  const p = useSpring(delay);
  return (
    <span
      style={{
        display: 'inline-block',
        marginRight: '0.26em',
        color: accent ? RED : '#fff',
        opacity: p,
        transform: `translateY(${interpolate(p, [0, 1], [50, 0])}px)`,
      }}
    >
      {word}
    </span>
  );
};

const FadeIn = ({ delay, children, style }) => {
  const p = useSpring(delay);
  return <div style={{ ...style, opacity: p, transform: `translateY(${interpolate(p, [0, 1], [24, 0])}px)` }}>{children}</div>;
};

/// A feature: the title above, the app on a phone below
const Scene = ({ title, subtitle, clip, extra }) => {
  const phone = useSpring(8, { damping: 18, mass: 0.9 });
  return (
    <AbsoluteFill style={background}>
      <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 500, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', textAlign: 'center' }}>
        <Words words={title} style={{ fontFamily: 'Literata', fontWeight: 700, fontSize: 88, lineHeight: 1.12, padding: '0 60px' }} />
        <FadeIn delay={title.length * 4 + 4} style={{ fontFamily: 'Roboto', fontSize: 42, color: GREY, lineHeight: 1.35, marginTop: 28, padding: '0 60px' }}>
          {subtitle}
        </FadeIn>
        {extra}
      </div>
      <div
        style={{
          position: 'absolute',
          left: 162,
          top: 522,
          width: 756,
          height: 1316,
          padding: 18,
          boxSizing: 'border-box',
          borderRadius: 70,
          background: '#2A2A2A',
          boxShadow: '0 40px 120px rgba(0,0,0,0.6)',
          opacity: Math.min(1, phone * 1.5),
          transform: `translateY(${interpolate(phone, [0, 1], [320, 0])}px)`,
        }}
      >
        <div style={{ width: 720, height: 1280, borderRadius: 52, overflow: 'hidden', background: '#000' }}>
          <OffthreadVideo src={staticFile(`clips/${clip}.mp4`)} muted style={{ width: 720, height: 1280 }} />
        </div>
      </div>
    </AbsoluteFill>
  );
};

/// A moving sound wave under the listening title
const SoundWave = () => {
  const frame = useCurrentFrame();
  const p = useSpring(20);
  return (
    <div style={{ display: 'flex', gap: 10, alignItems: 'center', height: 60, marginTop: 26, opacity: p }}>
      {[0, 1, 2, 3, 4, 5, 6].map(i => (
        <div
          key={i}
          style={{ width: 10, borderRadius: 5, background: RED, height: 14 + 40 * Math.abs(Math.sin(frame / 5 + i * 0.9)) }}
        />
      ))}
    </div>
  );
};

/// The focus letter of a word, as in the app (letters and digits only)
const orpIndex = word => {
  const letters = [...word].map((c, i) => (/[\p{L}\p{N}]/u.test(c) ? i : -1)).filter(i => i >= 0);
  if (letters.length === 0) return 0;
  const n = letters.length;
  const index = n <= 2 ? 0 : n <= 5 ? 1 : n <= 9 ? 2 : n <= 13 ? 3 : 4;
  return letters[Math.min(index, n - 1)];
};

/// A word shown like the speed reader: its focus letter red, on the guides
const RsvpWord = ({ word, size }) => {
  const i = orpIndex(word);
  const cw = size * 0.6; // Roboto Mono advance
  return (
    <div
      style={{
        position: 'absolute',
        left: 540 - (i + 0.5) * cw,
        top: -size * 0.66,
        fontFamily: 'Roboto Mono',
        fontWeight: 700,
        fontSize: size,
        lineHeight: 1,
        color: '#fff',
        whiteSpace: 'pre',
      }}
    >
      {word.slice(0, i)}
      <span style={{ color: RED }}>{word[i]}</span>
      {word.slice(i + 1)}
    </div>
  );
};

const INTRO_WORDS = ['Gözünü', 'tek', 'noktada', 'tut,', 'hızlı', 'oku.'];
const WORD_FRAMES = 9;
const RSVP_START = 10;
const LOGO_AT = RSVP_START + INTRO_WORDS.length * WORD_FRAMES + 6;

const Guides = ({ gap }) => (
  <>
    <div style={{ position: 'absolute', left: 537, top: -gap - 80, width: 6, height: 80, borderRadius: 3, background: RED }} />
    <div style={{ position: 'absolute', left: 537, top: gap, width: 6, height: 80, borderRadius: 3, background: RED }} />
  </>
);

const Intro = () => {
  const frame = useCurrentFrame();
  const word = INTRO_WORDS[Math.floor((frame - RSVP_START) / WORD_FRAMES)];
  const rsvpOut = interpolate(frame, [LOGO_AT - 6, LOGO_AT + 4], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const guidesIn = useSpring(0);
  const logo = useSpring(LOGO_AT, { damping: 14, mass: 0.8 });
  return (
    <AbsoluteFill style={background}>
      <div style={{ position: 'absolute', left: 0, top: 960, width: 1080, opacity: rsvpOut * guidesIn }}>
        <Guides gap={interpolate(guidesIn, [0, 1], [30, 110])} />
        {frame >= RSVP_START && word && <RsvpWord word={word} size={120} />}
      </div>
      <AbsoluteFill style={{ alignItems: 'center', justifyContent: 'center', flexDirection: 'column' }}>
        <Img
          src={staticFile('icon.png')}
          style={{ width: 300, height: 300, borderRadius: 66, opacity: Math.min(1, logo * 2), transform: `scale(${interpolate(logo, [0, 1], [0.5, 1])})` }}
        />
        <FadeIn delay={LOGO_AT + 8} style={{ fontFamily: 'Roboto', fontWeight: 500, fontSize: 112, color: '#fff', marginTop: 44 }}>
          RapidReader
        </FadeIn>
        <FadeIn delay={LOGO_AT + 18} style={{ fontFamily: 'Roboto', fontSize: 48, color: GREY, marginTop: 36, textAlign: 'center', lineHeight: 1.5 }}>
          Hızlı okuma · Rehberli okuma
          <br />
          Sesli okuma
        </FadeIn>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

const Chip = ({ label, delay }) => {
  const p = useSpring(delay, { damping: 12 });
  return (
    <div
      style={{
        fontFamily: 'Roboto',
        fontWeight: 500,
        fontSize: 46,
        color: '#fff',
        padding: '16px 34px',
        borderRadius: 999,
        border: `3px solid ${RED}`,
        opacity: Math.min(1, p * 2),
        transform: `scale(${interpolate(p, [0, 1], [0.4, 1])})`,
      }}
    >
      {label}
    </div>
  );
};

const Outro = () => {
  const logo = useSpring(0, { damping: 14, mass: 0.8 });
  return (
    <AbsoluteFill style={{ ...background, alignItems: 'center', justifyContent: 'center', flexDirection: 'column' }}>
      <Img
        src={staticFile('icon.png')}
        style={{ width: 260, height: 260, borderRadius: 58, opacity: Math.min(1, logo * 2), transform: `scale(${interpolate(logo, [0, 1], [0.6, 1])})` }}
      />
      <FadeIn delay={6} style={{ fontFamily: 'Roboto', fontWeight: 500, fontSize: 104, color: '#fff', marginTop: 40 }}>
        RapidReader
      </FadeIn>
      <FadeIn delay={16} style={{ fontFamily: 'Literata', fontWeight: 700, fontSize: 60, color: '#fff', marginTop: 90 }}>
        Kendi metinlerini de oku
      </FadeIn>
      <div style={{ display: 'flex', gap: 22, marginTop: 44 }}>
        {['TXT', 'PDF', 'EPUB', 'Web'].map((label, i) => (
          <Chip key={label} label={label} delay={26 + i * 5} />
        ))}
      </div>
      <FadeIn delay={56} style={{ fontFamily: 'Roboto', fontSize: 42, color: GREY, marginTop: 90 }}>
        Hesap gerekmez · Çevrim dışı okur
      </FadeIn>
    </AbsoluteFill>
  );
};

const scenes = [
  ['intro', <Intro />],
  ['speed', <Scene clip="speed" title={[['Kelime'], ['kelime'], ['\n'], ['hızlı', true], ['oku']]} subtitle="Gözün tek noktada kalır, hızı sen seçersin" />],
  ['modes', <Scene clip="modes" title={[['Bölümü'], ['istediğin'], ['gibi'], ['aç', true]]} subtitle="Hızlı okuma, düz metin ya da sesli okuma" />],
  ['guided', <Scene clip="guided" title={[['Rehberli', true], ['okuma']]} subtitle="Vurgu, seçtiğin hızda kelime kelime ilerler" />],
  ['listen', <Scene clip="listen" title={[['Sesli', true], ['okuma']]} subtitle="Türkçe sesle; ekran kapalıyken de devam eder" extra={<SoundWave />} />],
  ['home', <Scene clip="home" title={[['Kitaplığın'], ['cebinde', true]]} subtitle="Klasikler, Kur'an-ı Kerim meali ve kendi metinlerin" />],
  ['outro', <Outro />],
];

export const Promo = () => (
  <TransitionSeries>
    {scenes.flatMap(([name, scene], i) => [
      i > 0 && <TransitionSeries.Transition key={`t${i}`} presentation={fade()} timing={linearTiming({ durationInFrames: FADE })} />,
      <TransitionSeries.Sequence key={name} durationInFrames={SCENES[name]}>
        {scene}
      </TransitionSeries.Sequence>,
    ]).filter(Boolean)}
  </TransitionSeries>
);
