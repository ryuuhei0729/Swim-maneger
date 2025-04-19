// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"

// Stimulusアプリケーションの設定
import CalendarController from "./controllers/calendar_controller"
const application = Application.start()
application.register("calendar", CalendarController)
application.debug = true

// コントローラーの読み込み
import "./controllers"

export { application }



