import { Controller } from "@hotwired/stimulus"

// Auto-dismisses flash toasts after a delay with a fade-out.
export default class extends Controller {
  static values = { dismissAfter: { type: Number, default: 5000 } }

  connect() {
    this._timeout = setTimeout(() => this.dismiss(), this.dismissAfterValue)
  }

  disconnect() {
    clearTimeout(this._timeout)
    clearTimeout(this._fallbackTimeout)
  }

  dismiss() {
    this.element.classList.remove("opacity-100")
    this.element.classList.add("opacity-0")

    this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
    this._fallbackTimeout = setTimeout(() => this.element.remove(), 350)
  }
}
