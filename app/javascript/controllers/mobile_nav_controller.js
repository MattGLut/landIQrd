import { Controller } from "@hotwired/stimulus"

const OPEN_ARIA = "Open main menu"
const CLOSE_ARIA = "Close main menu"

// Toggles the small-viewport hamburger menu; does not run on md+ (panel is hidden in CSS).
export default class extends Controller {
  static targets = ["panel", "button", "iconMenu", "iconClose"]

  connect() {
    this._onClickOutside = this._clickOutside.bind(this)
    this._onTurboVisit = () => this.close()
    document.addEventListener("click", this._onClickOutside, true)
    document.addEventListener("turbo:visit", this._onTurboVisit)
  }

  disconnect() {
    document.removeEventListener("click", this._onClickOutside, true)
    document.removeEventListener("turbo:visit", this._onTurboVisit)
  }

  toggle() {
    if (this._isOpen()) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.panelTarget.classList.remove("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "true")
    this.buttonTarget.setAttribute("aria-label", CLOSE_ARIA)
    this.panelTarget.setAttribute("aria-hidden", "false")
    this.iconMenuTarget.classList.add("hidden")
    this.iconCloseTarget.classList.remove("hidden")
  }

  close() {
    if (!this.hasPanelTarget) {
      return
    }
    this.panelTarget.classList.add("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "false")
    this.buttonTarget.setAttribute("aria-label", OPEN_ARIA)
    this.panelTarget.setAttribute("aria-hidden", "true")
    this.iconMenuTarget.classList.remove("hidden")
    this.iconCloseTarget.classList.add("hidden")
  }

  keydown(event) {
    if (event.key !== "Escape" || !this._isOpen()) {
      return
    }
    event.preventDefault()
    this.close()
    this.buttonTarget.focus()
  }

  _isOpen() {
    return this.hasPanelTarget && !this.panelTarget.classList.contains("hidden")
  }

  _clickOutside(event) {
    if (!this._isOpen() || this.element.contains(event.target)) {
      return
    }
    this.close()
  }

  // Close when choosing a link or button inside the mobile panel (covers sign out before form submit).
  handlePanelNavigate(event) {
    if (event.target.closest("a[href], button")) {
      this.close()
    }
  }
}
