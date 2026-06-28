import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input" ]

  set(event) {
    this.inputTarget.value = this.#dateString(parseInt(event.currentTarget.dataset.deadlineDaysValue))
    this.#change()
  }

  clear() {
    this.inputTarget.value = ""
    this.#change()
  }

  #dateString(daysFromToday) {
    const date = new Date()
    date.setDate(date.getDate() + daysFromToday)

    return [
      date.getFullYear(),
      String(date.getMonth() + 1).padStart(2, "0"),
      String(date.getDate()).padStart(2, "0")
    ].join("-")
  }

  #change() {
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.inputTarget.form?.requestSubmit()
  }
}
