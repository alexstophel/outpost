import { Controller } from "@hotwired/stimulus"

// Converts UTC timestamps to the user's local timezone
// Usage: <span data-controller="local-time" data-local-time-value="2026-02-16T12:00:00Z"></span>
export default class extends Controller {
  static values = {
    datetime: String,
    format: { type: String, default: "time" } // "time", "date", "datetime", "relative"
  }

  connect() {
    this.render()
  }

  datetimeValueChanged() {
    this.render()
  }

  render() {
    const date = new Date(this.datetimeValue)
    
    if (isNaN(date.getTime())) {
      return
    }

    this.element.textContent = this.formatDate(date)
    this.element.setAttribute("title", this.formatFull(date))
  }

  formatDate(date) {
    switch (this.formatValue) {
      case "time":
        return this.formatTime(date)
      case "date":
        return this.formatDateOnly(date)
      case "datetime":
        return `${this.formatDateOnly(date)} ${this.formatTime(date)}`
      case "relative":
        return this.formatRelative(date)
      default:
        return this.formatTime(date)
    }
  }

  formatTime(date) {
    return date.toLocaleTimeString([], { 
      hour: 'numeric', 
      minute: '2-digit',
      hour12: true 
    })
  }

  formatDateOnly(date) {
    return date.toLocaleDateString([], {
      month: 'short',
      day: 'numeric'
    })
  }

  formatFull(date) {
    return date.toLocaleString([], {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    })
  }

  formatRelative(date) {
    const now = new Date()
    const diffMs = now - date
    const diffMins = Math.floor(diffMs / 60000)
    const diffHours = Math.floor(diffMs / 3600000)
    const diffDays = Math.floor(diffMs / 86400000)

    if (diffMins < 1) return "just now"
    if (diffMins < 60) return `${diffMins}m ago`
    if (diffHours < 24) return `${diffHours}h ago`
    if (diffDays < 7) return `${diffDays}d ago`
    
    return this.formatDateOnly(date)
  }
}
