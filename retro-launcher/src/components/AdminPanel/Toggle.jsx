import React from 'react'
import { HapticEngine } from '../HapticEngine/HapticEngine'

// iOS-style labelled toggle row used across Settings and Admin.
export default function Toggle({ label, desc, checked, onChange }) {
  return (
    <div className="toggle-row">
      <div>
        <div className="toggle-row__label">{label}</div>
        {desc && <div className="toggle-row__desc">{desc}</div>}
      </div>
      <label className="toggle">
        <input
          type="checkbox"
          checked={checked}
          onChange={(e) => { HapticEngine.fire('uiSelect'); onChange(e.target.checked) }}
        />
        <span className="toggle__track" />
        <span className="toggle__thumb" />
      </label>
    </div>
  )
}
