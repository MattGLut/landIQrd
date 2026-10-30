import { Controller } from "@hotwired/stimulus"

// Shows "n/max" under a textarea.
export default class extends Controller {
  static targets = ["input", "count"]
  static values = { max: Number }

  connect() {
    this.update()
  }

  update() {
    this.countTarget.textContent = `${this.inputTarget.value.length}/${this.maxValue}`
  }
}
