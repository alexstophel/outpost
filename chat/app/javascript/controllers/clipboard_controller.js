import { Controller } from "@hotwired/stimulus"

// Copies text from an input field to clipboard
// Usage: <div data-controller="clipboard">
//          <input data-clipboard-target="source" value="text to copy">
//          <button data-action="click->clipboard#copy">Copy</button>
//        </div>
export default class extends Controller {
  static targets = ["source"]

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.value)
  }
}
