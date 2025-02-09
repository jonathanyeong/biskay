import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "source", "counter", "submit" ]

  connect() {
    this.maxLengthValue = 300
  }

  validateLength() {
    const remaining = this.maxLengthValue - this.sourceTarget.value.length
    this.counterTarget.textContent = `${remaining} characters remaining`
    // Update counter color based on remaining characters
    if (remaining < 0) {
      this.counterTarget.classList.remove("text-amber-600", "text-gray-500")
      this.counterTarget.classList.add("text-red-600")
      this.submitTarget.disabled = true
      this.submitTarget.classList.add("bg-indigo-400", "cursor-not-allowed")
      this.submitTarget.classList.remove("bg-indigo-600", "hover:bg-indigo-500")
    } else if (remaining <= 20) {
      this.counterTarget.classList.remove("text-red-600", "text-gray-500")
      this.counterTarget.classList.add("text-amber-600")
      this.submitTarget.disabled = false
      this.submitTarget.classList.add("bg-indigo-600", "hover:bg-indigo-500")
      this.submitTarget.classList.remove("bg-indigo-400", "cursor-not-allowed")
    } else {
      this.counterTarget.classList.remove("text-red-600", "text-amber-600")
      this.counterTarget.classList.add("text-gray-500")
      this.submitTarget.disabled = false
      this.submitTarget.classList.add("bg-indigo-600", "hover:bg-indigo-500")
      this.submitTarget.classList.remove("bg-indigo-400", "cursor-not-allowed")
    }
  }
}