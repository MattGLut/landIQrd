import { Controller } from "@hotwired/stimulus"

// Tap toggle. iOS Safari drops :hover and :focus-within on a sticky header
// before click, so a single tap did nothing and a long-press selected the label.
export default class extends Controller {
  static targets = ["button", "menu"]

  toggle() {
    if (this._isOpen()) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    if (!this.hasMenuTarget) return

    this.menuTarget.classList.add("hidden")
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "false")
    }
  }

  closeIfOutside(event) {
    if (!this._isOpen() || this.element.contains(event.target)) return

    this.close()
  }

  keydown(event) {
    if (event.key !== "Escape" || !this._isOpen()) return

    event.preventDefault()
    this.close()
    this.buttonTarget.focus()
  }

  _isOpen() {
    return this.hasMenuTarget && !this.menuTarget.classList.contains("hidden")
  }
}
