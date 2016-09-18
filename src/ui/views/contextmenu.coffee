remote = require('electron').remote
ContextMenu = remote.Menu


templateContext = [
  {
    label: 'Undo'
    role: 'undo'
  }
  {
    label: 'Redo'
    role: 'redo'
  }
  { type: 'separator' }
  {
    label: 'Cut'
    role: 'cut'
  }
  {
    label: 'Copy'
    role: 'copy'
  }
  {
    label: 'Paste'
    role: 'paste'
  }
]

module.exports = ContextMenu.buildFromTemplate templateContext
