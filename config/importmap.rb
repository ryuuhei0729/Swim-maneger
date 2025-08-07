# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin "tw-elements", to: "https://cdn.jsdelivr.net/npm/tw-elements@1.0.0-beta2/dist/js/tw-elements.umd.min.js"
# コントローラーを明示的に追加
pin "controllers/calendar_controller", to: "controllers/calendar_controller.js"
pin "controllers/modal_controller", to: "controllers/modal_controller.js"
pin "controllers/member_controller", to: "controllers/member_controller.js"
pin "controllers/sidebar_controller", to: "controllers/sidebar_controller.js"
# 他のコントローラーは自動 pin
pin_all_from "app/javascript/controllers", under: "controllers/"
