import { marked } from 'marked'

const nav = document.getElementById('nav')
const content = document.getElementById('content')
const scrim = document.getElementById('scrim')
const menuToggle = document.getElementById('menu-toggle')

marked.setOptions({ gfm: true, breaks: false })

function closeNav() {
  document.body.classList.remove('nav-open')
}

async function fetchText(path) {
  const res = await fetch(path)
  if (!res.ok) throw new Error(`Failed to load ${path} (${res.status})`)
  return res.text()
}

async function loadDoc(doc, button) {
  document.querySelectorAll('.nav-item').forEach((n) => n.classList.remove('active'))
  if (button) button.classList.add('active')
  content.innerHTML = '<p class="loading">Loading…</p>'
  try {
    const md = await fetchText(`docs/${doc.file}`)
    content.innerHTML = marked.parse(md)
    content.scrollTop = 0
    // External links open in a new tab; Tauri/web safe.
    content.querySelectorAll('a[href^="http"]').forEach((a) => {
      a.target = '_blank'
      a.rel = 'noopener noreferrer'
    })
  } catch (err) {
    content.innerHTML = `<p class="error">Could not load this document.<br><code>${err.message}</code></p>`
  }
  closeNav()
  if (location.hash !== `#${doc.id}`) history.replaceState(null, '', `#${doc.id}`)
}

function buildNav(manifest) {
  const flat = []
  manifest.groups.forEach((group) => {
    const heading = document.createElement('div')
    heading.className = 'nav-group'
    heading.textContent = group.title
    nav.appendChild(heading)
    group.docs.forEach((doc) => {
      const btn = document.createElement('button')
      btn.className = 'nav-item'
      btn.textContent = doc.title
      btn.addEventListener('click', () => loadDoc(doc, btn))
      nav.appendChild(btn)
      flat.push({ doc, btn })
    })
  })
  return flat
}

async function init() {
  let manifest
  try {
    manifest = JSON.parse(await fetchText('docs/manifest.json'))
  } catch (err) {
    content.innerHTML = `<p class="error">Could not load the document index.<br><code>${err.message}</code></p>`
    return
  }
  const flat = buildNav(manifest)
  const fromHash = location.hash.slice(1)
  const start = flat.find((f) => f.doc.id === fromHash) || flat[0]
  if (start) loadDoc(start.doc, start.btn)
}

menuToggle.addEventListener('click', () => document.body.classList.toggle('nav-open'))
scrim.addEventListener('click', closeNav)
window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') closeNav()
})

init()
