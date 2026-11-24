// Reference backend (Node 18+). The AI provider key lives ONLY here.
// Run:  cd backend && cp .env.example .env && npm i express && node --env-file=.env server.js
const express = require('express');
const app = express();
app.use(express.json({ limit: '200kb' }));

const { APP_TOKEN, ANTHROPIC_API_KEY, MODEL = 'claude-sonnet-5-5', PORT = 8080 } = process.env;

app.use((req, res, next) => {
  if (APP_TOKEN && req.get('Authorization') !== `Bearer ${APP_TOKEN}`) return res.sendStatus(401);
  next();
});

async function llm(system, user) {
  if (!ANTHROPIC_API_KEY) throw new Error('no key');
  const r = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: { 'x-api-key': ANTHROPIC_API_KEY, 'anthropic-version': '2023-06-01', 'content-type': 'application/json' },
    body: JSON.stringify({ model: MODEL, max_tokens: 900, system, messages: [{ role: 'user', content: user }] }),
  });
  if (!r.ok) throw new Error(`llm ${r.status}`);
  const j = await r.json();
  const text = j.content.map((c) => c.text || '').join('');
  return JSON.parse(text.replace(/```json|```/g, '').trim());
}

const EXAMINER = `You are a friendly, professional English oral examiner for beginners (Oxford Speak Now 1 level).
Speak simple English only. Ask ONE question at a time. Never give the correct answer. Reply ONLY with JSON:
{"text": string, "lessonId": number|null, "isFollowUp": boolean}`;

const EVALUATOR = `You evaluate a beginner's spoken English answer (transcribed by speech recognition, so punctuation/capitalisation
errors are NOT the student's fault; low confidence means possible recognition errors). Reply ONLY with JSON:
{"scores":{"grammar":0-10,"vocabulary":0-10,"pronunciation":number|null,"fluency":0-10,"relevance":0-10,"completeness":0-10},
"total":0-10,"corrected":string,"feedbackFa":[Persian strings],"betterExpressions":[string],"suggestedVocab":[string],
"improvedExample":string,"pronunciationApprox":true,"recognitionUncertain":boolean}
Use pronunciation=null if confidence<=0. Never give a perfect score if there are significant errors.`;

app.post('/examiner/next', async (req, res) => {
  try { res.json(await llm(EXAMINER, JSON.stringify(req.body))); }
  catch (e) { res.sendStatus(502); }   // app falls back to local demo mode
});
app.post('/evaluate', async (req, res) => {
  try { res.json(await llm(EVALUATOR, JSON.stringify(req.body))); }
  catch (e) { res.sendStatus(502); }
});
app.get('/health', (_, res) => res.send('ok'));
app.listen(PORT, () => console.log(`listening on ${PORT}`));
