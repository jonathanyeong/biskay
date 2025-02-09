import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "skeet", "counter", "submit" ]

  connect() {
    this.maxLengthValue = 300
  }

  validateLength() {
    const remaining = this.maxLengthValue - this.skeetTarget.value.length
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

  checkScheduledDate() {
    const day = document.getElementById("scheduled_at_datetime_3i")
    const month = document.getElementById("scheduled_at_datetime_2i")
    const year = document.getElementById("scheduled_at_datetime_1i")
    const hour = document.getElementById("scheduled_at_datetime_4i")
    const minute = document.getElementById("scheduled_at_datetime_5i")
    const scheduledDate = new Date(year.value, (month.value - 1), day.value, hour.value, minute.value)
    if (scheduledDate > Date.now()) {
      this.submitTarget.value = "Schedule"
    } else {
      this.submitTarget.value = "Post"
    }
  }
}
