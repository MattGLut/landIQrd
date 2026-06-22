// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "controllers"

const FLASH_DISMISS_MS = 5000
const FLASH_FADE_MS = 500

function dismissFlashMessages() {
  document.querySelectorAll("[data-flash-auto-dismiss]:not([data-dismiss-scheduled])").forEach((element) => {
    element.dataset.dismissScheduled = "true"

    setTimeout(() => {
      element.classList.add("is-dismissing")
      setTimeout(() => {
        const container = element.closest(".flash-container")
        element.remove()
        if (container && !container.querySelector("[data-flash-auto-dismiss]")) {
          container.remove()
        }
      }, FLASH_FADE_MS)
    }, FLASH_DISMISS_MS)
  })
}

document.addEventListener("turbo:load", dismissFlashMessages)
document.addEventListener("DOMContentLoaded", dismissFlashMessages)
