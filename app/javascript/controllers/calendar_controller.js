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
    event.preventDefault()
    const currentDate = new Date(this.currentMonthTarget.value)
    currentDate.setMonth(currentDate.getMonth() - 1)
    this.updateCalendar(currentDate)
  }

  nextMonth(event) {
    event.preventDefault()
    const currentDate = new Date(this.currentMonthTarget.value)
    currentDate.setMonth(currentDate.getMonth() + 1)
    this.updateCalendar(currentDate)
  }

  today(event) {
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
    const month = date.getMonth() + 1
    
    // リクエスト先を修正
    fetch(`/attendance?month=${date.toISOString().split('T')[0]}`, {
      method: 'GET',
      headers: {
        'Accept': 'text/javascript',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('Network response was not ok')
      }
      return response.text()
    })
    .then(html => {
      console.log("Received response")
      const parser = new DOMParser()
      const doc = parser.parseFromString(html, 'text/html')
      const newCalendar = doc.querySelector('#calendar')
      
      if (newCalendar) {
        // 現在のカレンダーを新しいカレンダーで完全に置き換え
        const newCalendarContent = newCalendar.innerHTML
        this.element.innerHTML = newCalendarContent
        
        // ターゲットを再取得
        this.currentMonthTarget = this.element.querySelector('[data-calendar-target="currentMonth"]')
        this.headerTarget = this.element.querySelector('[data-calendar-target="header"]')
        
        // 日付を更新
        this.currentMonthTarget.value = date.toISOString().split('T')[0]
        this.headerTarget.textContent = `${date.getFullYear()}年${month}月`
        
        // Stimulusコントローラーを再接続
        this.application.connect()
        
        // デバッグ用：カレンダーの状態を確認
        console.log('Current month value:', this.currentMonthTarget.value)
        console.log('Header text:', this.headerTarget.textContent)
        console.log('Calendar content updated')
      } else {
        throw new Error('Calendar element not found in response')
      }
    })
    .catch(error => {
      console.error('Error updating calendar:', error)
      alert('カレンダーの更新に失敗しました。ページをリロードしてください。')
    })
  }
} 