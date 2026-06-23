import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "master", "type" ]

  toggleAll() {
    const enabled = this.masterTarget.checked
    this.typeTargets.forEach((checkbox) => {
      checkbox.checked = enabled
    })
    this.submit()
  }

  typeChanged() {
    this.syncMaster()
    this.submit()
  }

  syncMaster() {
    this.masterTarget.checked = this.typeTargets.every((checkbox) => checkbox.checked)
  }

  submit() {
    this.element.requestSubmit()
  }
}
