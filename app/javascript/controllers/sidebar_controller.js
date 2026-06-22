import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "panel", "overlay" ]

  toggle() {
    if (this.panelTarget.classList.contains("-translate-x-full")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.panelTarget.classList.remove("-translate-x-full")
    this.overlayTarget.classList.remove("hidden")
  }

  close() {
    this.panelTarget.classList.add("-translate-x-full")
    this.overlayTarget.classList.add("hidden")
  }
}
