import { Controller } from "@hotwired/stimulus"

// Positions a fixed flash container below a measured element (e.g. the app header).
export default class extends Controller {
  static values = { offsetTarget: String, gap: { type: Number, default: 8 } }

  connect() {
    this._position = this._position.bind(this)
    this._target = document.querySelector(this.offsetTargetValue)

    if (this._target) {
      this._position()
      this._ro = new ResizeObserver(this._position)
      this._ro.observe(this._target)
      window.addEventListener("resize", this._position)
    }
  }

  disconnect() {
    this._ro?.disconnect()
    window.removeEventListener("resize", this._position)
  }

  _position() {
    if (!this._target) return

    const height = this._target.getBoundingClientRect().height
    this.element.style.top = `${height + this.gapValue}px`
  }
}
