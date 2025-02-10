import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "skeet", "counter", "submit", "dropdown" ]

  connect() {
    this.maxLengthValue = 300
    this.isOpen = false
    this.selectedIndex = -1
  }

  onInput() {
    this.validateLength()
    const cursorPosition = this.skeetTarget.selectionStart
    const textBeforeCursor = this.skeetTarget.value.slice(0, cursorPosition)
    const match = textBeforeCursor.match(/@\w+$/)
    if (match) {
      const query = match[0].slice(1)
      this.fetchSuggestions(query)
    }
  }

  onKeydown(event) {
    if (!this.isOpen) return
    event.preventDefault()

    switch(event.key) {
      case 'ArrowDown':
        this.selectedIndex = Math.min(
          this.selectedIndex + 1,
          this.dropdownTarget.querySelectorAll('li').length - 1
        )
        this.updateHighlight()
        break
      case 'ArrowUp':
        this.selectedIndex = Math.max(this.selectedIndex - 1, 0)
        this.updateHighlight()
        break
      case 'Enter':
        if (this.selectedIndex >= 0) {
          const selectedUser = this.dropdownTarget.querySelectorAll('li')[this.selectedIndex]
          this.selectUser({ currentTarget: selectedUser })
        }
        break
      case 'Escape':
        this.hideDropdown()
        break
    }
  }

  updateHighlight() {
    this.dropdownTarget.querySelectorAll('li').forEach((li, index) => {
      if (index === this.selectedIndex) {
        li.classList.add('bg-gray-100')
      } else {
        li.classList.remove('bg-gray-100')
      }
    })
  }

  selectUser(event) {
    const handle = event.currentTarget.dataset.userHandle
    const textarea = this.skeetTarget
    const cursorPosition = textarea.selectionStart
    const textBeforeCursor = textarea.value.slice(0, cursorPosition)
    const textAfterCursor = textarea.value.slice(cursorPosition)
    const lastAtSign = textBeforeCursor.lastIndexOf('@')

    textarea.value =
      textBeforeCursor.slice(0, lastAtSign) +
      `@${handle} ` +
      textAfterCursor

    this.hideDropdown()
    textarea.focus()
    this.validateLength() // Don't forget to validate length after inserting text
  }

  async fetchSuggestions(query) {
    try {
      const response = await fetch(`/skeets/search_actors?q=${encodeURIComponent(query)}`, {
        headers: {
          'Accept': 'text/vnd.turbo-stream.html'
        }
      })
      if (response.ok) {
        const html = await response.text()
        this.dropdownTarget.innerHTML = html
        this.dropdownTarget.classList.remove('hidden')
        this.isOpen = true
        this.selectedIndex = -1
      }
    } catch (error) {
      console.error('Error fetching suggestions:', error)
    }
  }

  hideDropdown() {
    this.dropdownTarget.classList.add('hidden')
    this.isOpen = false
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
