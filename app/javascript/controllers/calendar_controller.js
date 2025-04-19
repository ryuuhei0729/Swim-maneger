import { Controller } from "@hotwired/stimulus"

// カレンダーコントローラーの定義
export default class extends Controller {
  static targets = ["currentMonth", "header"]

  initialize() {
    console.log("Calendar controller initialized")
  }

  connect() {
    console.log("Calendar controller connected")
    console.log("Targets:", this.targets)
  }

  prevMonth(event) {
    console.log("prevMonth called")
    event.preventDefault()
    const currentDate = new Date(this.currentMonthTarget.value)
    currentDate.setMonth(currentDate.getMonth() - 1)
    this.updateCalendar(currentDate)
  }

  nextMonth(event) {
    console.log("nextMonth called")
    event.preventDefault()
    const currentDate = new Date(this.currentMonthTarget.value)
    currentDate.setMonth(currentDate.getMonth() + 1)
    this.updateCalendar(currentDate)
  }

  today(event) {
    console.log("today called")
    event.preventDefault()
    this.updateCalendar(new Date())
  }

  parseCurrentDate() {
    const headerText = this.element.querySelector("h3").textContent
    const match = headerText.match(/(\d{4})年(\d{1,2})月/)
    if (match) {
      const [_, year, month] = match
      return new Date(parseInt(year), parseInt(month) - 1, 1)
    }
    return new Date()
  }

  updateCalendar(date) {
    console.log("updateCalendar called with date:", date)
    this.currentMonthTarget.value = date.toISOString().split('T')[0]
    this.headerTarget.textContent = `${date.getFullYear()}年${date.getMonth() + 1}月`
    
    // AJAXリクエストを送信
    fetch(`/attendance?month=${date.toISOString().split('T')[0]}`, {
      headers: {
        'Accept': 'text/javascript',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.text())
    .then(html => {
      console.log("Received response")
      const parser = new DOMParser()
      const doc = parser.parseFromString(html, 'text/html')
      const newCalendar = doc.querySelector('#calendar')
      if (newCalendar) {
        this.element.replaceWith(newCalendar)
      }
    })
    .catch(error => {
      console.error("Error updating calendar:", error)
    })
  }
} 