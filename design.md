project:
  name: "AI English Dictionary"
  name_zh_tw: "AI WordPilot－AI 單字領航"
  version: "1.0.0"
  project_type: "Cross-platform Mobile Application"
  description: >
    可發布至 Android 與 Apple App Store 的 AI WordPilot－AI 單字領航 App。
    使用者可以輸入英文或繁體中文，透過 LLM 查詢對應的英文單字、
    詞義、音標、例句、詞性、變化形及相關用法。
    App 不使用傳統字典資料庫，查詢內容由 LLM 即時產生。
  positioning:
    - "AI WordPilot"
    - "英文單字學習助手"
    - "中英文雙向查詢工具"

platforms:
  supported:
    - android
    - ios
  optional_future:
    - web
  app_store_targets:
    android: "Google Play"
    ios: "Apple App Store"

technology_stack:
  frontend:
    framework: "Flutter"
    language: "Dart"
    minimum_flutter_version: "依開發時最新穩定版本決定"
  state_management:
    recommended: "Riverpod"
  routing:
    recommended: "go_router"
  http_client:
    recommended: "dio"
  serialization:
    recommended:
      - "json_serializable"
      - "freezed"
  local_storage:
    favorites:
      format: "JSON"
      recommended_implementation:
        - "Application Documents Directory"
        - "path_provider"
        - "dart:io"
    settings:
      normal_data: "shared_preferences"
      api_key: "flutter_secure_storage"
  text_to_speech:
    package: "flutter_tts"
  icons:
    package: "Material Icons 或 Cupertino Icons"

architecture:
  pattern: "Feature-first layered architecture"
  layers:
    presentation:
      responsibility:
        - "UI Widget"
        - "頁面狀態"
        - "使用者操作"
    application:
      responsibility:
        - "查詢流程"
        - "收藏流程"
        - "設定流程"
    domain:
      responsibility:
        - "DictionaryEntry"
        - "FavoriteWord"
        - "LLMProvider"
        - "AppSettings"
    infrastructure:
      responsibility:
        - "OpenAI API client"
        - "Gemini API client"
        - "Secure Storage"
        - "JSON favorites repository"

  suggested_directory_structure:
    - "lib/main.dart"
    - "lib/app.dart"
    - "lib/core/constants/"
    - "lib/core/errors/"
    - "lib/core/network/"
    - "lib/core/storage/"
    - "lib/core/theme/"
    - "lib/core/widgets/"
    - "lib/features/dictionary/data/"
    - "lib/features/dictionary/domain/"
    - "lib/features/dictionary/presentation/"
    - "lib/features/settings/data/"
    - "lib/features/settings/domain/"
    - "lib/features/settings/presentation/"
    - "lib/features/favorites/data/"
    - "lib/features/favorites/domain/"
    - "lib/features/favorites/presentation/"

navigation:
  initial_route: "/dictionary"
  routes:
    dictionary:
      path: "/dictionary"
      screen: "DictionaryScreen"
    settings:
      path: "/settings"
      screen: "SettingsScreen"
    favorites:
      path: "/favorites"
      screen: "FavoritesScreen"

  navigation_rules:
    - from: "DictionaryScreen"
      action: "點選設定圖示"
      to: "SettingsScreen"
    - from: "DictionaryScreen"
      action: "點選右上角清單按鈕"
      to: "FavoritesScreen"
    - from: "SettingsScreen"
      action: "返回"
      to: "DictionaryScreen"
    - from: "FavoritesScreen"
      action: "點選收藏單字"
      to: "DictionaryScreen"
      parameters:
        - "word"
        - "autoQuery"

ui_design:
  language: "繁體中文"
  responsive: true
  themes:
    - light
    - dark
    - system
  design_style:
    - "簡潔"
    - "容易閱讀"
    - "字典資訊分區顯示"
    - "適合手機直向操作"

screens:
  dictionary_screen:
    id: "UI-01"
    name: "字典查詢主畫面"
    route: "/dictionary"

    app_bar:
      title: "AI WordPilot"
      leading: null
      actions:
        settings_button:
          icon: "settings_outlined"
          tooltip: "設定"
          action: "navigate_to_settings"
        favorites_list_button:
          icon: "list_alt_outlined"
          tooltip: "我的單字清單"
          action: "navigate_to_favorites"

    components:
      search_input:
        type: "TextField"
        id: "dictionaryQueryText"
        label: "輸入英文或中文"
        hint: "例如：apple、堅持、look forward to"
        keyboard_action: "search"
        max_length: 200
        clear_button: true
        supported_input:
          - english_word
          - english_phrase
          - english_sentence
          - traditional_chinese_word
          - traditional_chinese_phrase
        validation:
          required: true
          trim_whitespace: true
          reject_empty_string: true
        events:
          on_submit: "execute_dictionary_query"

      search_button:
        type: "IconButton"
        icon: "search"
        tooltip: "查詢"
        enabled_when:
          - "查詢文字不為空"
          - "目前沒有執行查詢"
        action: "execute_dictionary_query"

      favorite_button:
        type: "IconButton"
        default_icon: "star_border"
        selected_icon: "star"
        tooltip_default: "加入我的單字"
        tooltip_selected: "移除我的單字"
        states:
          not_favorite:
            icon: "star_border"
            meaning: "空心星星"
          favorite:
            icon: "star"
            meaning: "實心星星"
        enabled_when:
          - "目前有有效的英文單字查詢結果"
        action: "toggle_favorite"

      result_area:
        type: "ScrollableResultView"
        original_requirement_name: "AreaText"
        recommendation: >
          不建議只使用單一大型 TextArea 顯示結果。
          建議使用可捲動的 Card、Section、SelectableText，
          讓音標、詞性、解釋和例句分區呈現。
        empty_state:
          icon: "menu_book_outlined"
          title: "開始查詢英文單字"
          message: "請輸入英文或中文內容。"
        loading_state:
          widget: "CircularProgressIndicator"
          message: "正在查詢..."
        error_state:
          show_retry_button: true
        success_state:
          selectable_text: true
          scrollable: true

    layout_order:
      - "AppBar"
      - "SearchInputRow"
      - "FavoriteButton"
      - "QueryStatus"
      - "DictionaryResultArea"

    user_flows:
      query:
        steps:
          - "使用者在查詢欄輸入英文或中文"
          - "使用者點選搜尋圖示或鍵盤搜尋"
          - "系統驗證輸入內容"
          - "系統載入目前選定的 LLM 供應商、模型與 API Key"
          - "若使用者未設定 API Key，判斷是否可以使用 App 預設服務"
          - "系統建立字典查詢 Prompt"
          - "呼叫選定的 LLM API"
          - "驗證 LLM 回傳的 JSON"
          - "轉換為 DictionaryEntry"
          - "在結果區分段顯示"
          - "重新判斷該單字是否已收藏"

      add_favorite:
        preconditions:
          - "查詢成功"
          - "結果包含 normalizedWord"
        steps:
          - "使用者點選空心星星"
          - "星星立即切換成實心"
          - "建立 FavoriteWord JSON Object"
          - "檢查是否已經存在相同 normalizedWord"
          - "若不存在，寫入手機 favorites.json"
          - "顯示已加入我的單字提示"

      remove_favorite:
        steps:
          - "使用者點選實心星星"
          - "星星切換成空心"
          - "從 favorites.json 移除該單字"
          - "顯示已從清單移除提示"

  settings_screen:
    id: "UI-02"
    name: "設定"
    route: "/settings"

    app_bar:
      title: "模型設定"
      back_button: true

    components:
      provider_selector:
        type: "DropdownButtonFormField"
        label: "LLM 供應商"
        options:
          - id: "gemini"
            name: "Google Gemini"
          - id: "openai"
            name: "OpenAI"
        required: true

      model_selector:
        type: "DropdownButtonFormField"
        label: "模型"
        source: "依選定供應商顯示模型"
        options_by_provider:
          gemini:
            default: "gemini-2.5-flash"
            models:
              - id: "gemini-2.5-flash"
                name: "Gemini 2.5 Flash"
              - id: "custom"
                name: "自訂模型名稱"
          openai:
            default: "由產品版本設定"
            models:
              - id: "recommended_small_model"
                name: "推薦低成本模型"
              - id: "custom"
                name: "自訂模型名稱"
        note: "模型名稱必須由設定檔維護，避免寫死過時的模型清單。"

      custom_model_input:
        type: "TextField"
        label: "自訂模型名稱"
        visible_when: "model == custom"
        required_when_visible: true

      api_key_input:
        type: "TextField"
        label: "API Key"
        obscure_text: true
        enable_suggestions: false
        autocorrect: false
        allow_paste: true
        show_toggle_visibility: true
        storage: "flutter_secure_storage"
        never_store_in:
          - "SharedPreferences"
          - "SQLite"
          - "JSON file"
          - "Application log"
          - "Crash log"

      masked_api_key:
        type: "Text"
        example: "AIza••••••••••7Qx9"
        visible_when: "已存在 API Key"

      validate_key_button:
        type: "OutlinedButton"
        label: "測試連線"
        action: "validate_api_key"
        behavior:
          - "使用低成本、最小輸出的請求測試"
          - "成功時顯示連線成功"
          - "失敗時不顯示完整 API Key"
          - "不得將 API Key 寫入日誌"

      save_button:
        type: "FilledButton"
        label: "儲存設定"
        action: "save_llm_settings"

      delete_key_button:
        type: "TextButton"
        label: "刪除 API Key"
        style: "destructive"
        confirmation_required: true
        action: "delete_api_key"

      optional_preferences:
        output_language:
          type: "Dropdown"
          default: "zh-TW"
          options:
            - "zh-TW"
            - "English"
        english_variant:
          type: "SegmentedButton"
          default: "both"
          options:
            - "US"
            - "UK"
            - "both"
        learner_level:
          type: "Dropdown"
          default: "intermediate"
          options:
            - "beginner"
            - "intermediate"
            - "advanced"
        theme:
          type: "Dropdown"
          default: "system"
          options:
            - "system"
            - "light"
            - "dark"

    storage_rules:
      secure_storage:
        fields:
          - "apiKey"
      shared_preferences:
        fields:
          - "provider"
          - "model"
          - "customModel"
          - "outputLanguage"
          - "englishVariant"
          - "learnerLevel"
          - "theme"

    validation_rules:
      - "必須選擇供應商"
      - "必須選擇或輸入模型"
      - "API Key 不可為空白"
      - "API Key 前後空白必須移除"
      - "儲存前建議先測試連線"
      - "切換供應商時，不自動刪除其他供應商的 Key"
      - "不同供應商的 API Key 使用不同的 Secure Storage Key"

    secure_storage_keys:
      gemini: "llm_api_key_gemini"
      openai: "llm_api_key_openai"

  favorites_screen:
    id: "UI-03"
    name: "我的清單"
    route: "/favorites"

    app_bar:
      title: "我的單字"
      back_button: true
      optional_actions:
        - "排序"
        - "搜尋收藏"
        - "清除全部"

    components:
      search_favorites:
        type: "TextField"
        hint: "搜尋我的單字"
        optional_for_mvp: true

      word_list:
        type: "ListView"
        item_type: "FavoriteWordTile"
        empty_state:
          icon: "star_border"
          title: "尚未收藏單字"
          message: "在查詢結果點選星星，即可加入清單。"

      favorite_word_tile:
        displayed_fields:
          - "word"
          - "phonetic"
          - "primaryPartOfSpeech"
          - "primaryTranslationZhTw"
          - "savedAt"
        actions:
          tap:
            - "回到字典主畫面"
            - "將單字填入查詢欄"
            - "顯示已儲存結果或重新查詢"
          delete:
            - "從 favorites.json 移除"
          swipe_to_delete:
            enabled: true
            confirmation_required: false

    sorting:
      default: "savedAt_desc"
      options:
        - id: "savedAt_desc"
          label: "最近加入"
        - id: "word_asc"
          label: "A 到 Z"
        - id: "word_desc"
          label: "Z 到 A"

dictionary_query:
  accepted_input_types:
    english_word:
      example: "persistent"
      expected_behavior: "查詢該英文單字"
    english_phrase:
      example: "look forward to"
      expected_behavior: "解析片語與使用方式"
    english_sentence:
      example: "I look forward to meeting you."
      expected_behavior: "辨識重點單字或片語並解釋"
    traditional_chinese:
      example: "堅持"
      expected_behavior: >
        找出最符合語境的英文單字，並提供其他可能翻譯及用法差異。

  default_provider:
    provider: "gemini"
    model: "gemini-2.5-flash"

  provider_strategy:
    mode: "User-configurable BYOK"
    priority:
      - "使用者在設定 UI 儲存的 API Key"
      - "App 預設後端服務，可作為未來選配"
    note: >
      使用者輸入的 API Key 應儲存在手機 Secure Storage。
      不應把使用者 API Key寫入環境變數。
      環境變數適合保存 App 開發者自己的後端 API Key，
      而且只能存在後端，不能打包進 Flutter App。

  execution:
    timeout_seconds: 30
    retry_count: 1
    temperature: 0.1
    response_format: "Strict JSON"
    streaming:
      enabled: false
      future_option: true

  prompt:
    system_prompt: |
      You are an AI English dictionary and English-learning assistant.

      The user may enter English or Traditional Chinese.

      Your tasks:
      1. If the input is English, identify and explain the English word,
         phrase, or important vocabulary in the sentence.
      2. If the input is Traditional Chinese, return the most appropriate
         English word or phrase and include alternative translations when useful.
      3. Use Traditional Chinese for translations and learning notes.
      4. Include concise English definitions.
      5. Separate meanings by part of speech.
      6. Order meanings from common to less common.
      7. Provide IPA pronunciation only when reasonably confident.
      8. Include natural example sentences with Traditional Chinese translations.
      9. Include common collocations, phrases, word forms, synonyms, antonyms,
         and usage notes when applicable.
      10. Explain important differences between alternative English translations.
      11. Do not claim the content comes from Oxford, Cambridge, Longman,
          Merriam-Webster, or any published dictionary.
      12. Do not invent rare meanings.
      13. When uncertain, add a warning.
      14. Return valid JSON only.
      15. Follow the supplied JSON schema exactly.

  request_context:
    fields:
      - "query"
      - "outputLanguage"
      - "learnerLevel"
      - "englishVariant"
      - "responseSchemaVersion"

  expected_dictionary_result_items:
    basic_information:
      - "查詢原文"
      - "標準化英文單字"
      - "其他可能英文翻譯"
      - "音節"
      - "美式 IPA"
      - "英式 IPA"
      - "詞性"
      - "CEFR 程度"
      - "常用程度"
    meanings:
      - "英文解釋"
      - "繁體中文翻譯"
      - "語意說明"
      - "例句"
      - "例句繁體中文翻譯"
    grammar:
      - "動詞變化"
      - "名詞單複數"
      - "形容詞比較級與最高級"
      - "可數或不可數"
      - "及物或不及物"
    related_vocabulary:
      - "同義字"
      - "反義字"
      - "字族"
      - "相關單字"
      - "常用片語"
      - "常見搭配"
    learning_notes:
      - "使用情境"
      - "容易混淆的字"
      - "正式或非正式程度"
      - "常見錯誤"
      - "中翻英差異"
    metadata:
      - "AI 警告"
      - "模型供應商"
      - "模型名稱"
      - "查詢時間"

data_models:
  dictionary_entry:
    schema_version: "1.0"
    fields:
      query:
        type: "string"
        required: true
      detectedInputLanguage:
        type: "string"
        enum:
          - "en"
          - "zh-TW"
          - "mixed"
          - "unknown"
      word:
        type: "string"
        description: "主要英文單字或片語"
      normalizedWord:
        type: "string"
        description: "小寫、移除不必要空白後的標準識別值"
      alternatives:
        type: "array"
        item:
          type: "TranslationAlternative"
      syllables:
        type: "array<string>"
      phonetics:
        type: "Phonetics"
      cefrLevel:
        type: "string|null"
      frequency:
        type: "string|null"
        enum:
          - "very_common"
          - "common"
          - "less_common"
          - "rare"
          - null
      meanings:
        type: "array"
        item:
          type: "DictionaryMeaning"
      wordForms:
        type: "WordForms|null"
      synonyms:
        type: "array<string>"
      antonyms:
        type: "array<string>"
      wordFamily:
        type: "array<RelatedWord>"
      collocations:
        type: "array<Collocation>"
      phrases:
        type: "array<Phrase>"
      confusingWords:
        type: "array<ConfusingWord>"
      usageNotes:
        type: "array<string>"
      commonMistakes:
        type: "array<string>"
      warnings:
        type: "array<string>"
      generatedAt:
        type: "ISO-8601 datetime"
      provider:
        type: "string"
      model:
        type: "string"

  phonetics:
    fields:
      ipaUS:
        type: "string|null"
      ipaUK:
        type: "string|null"
      pronunciationText:
        type: "string|null"

  translation_alternative:
    fields:
      word:
        type: "string"
      translationZhTw:
        type: "string"
      difference:
        type: "string"
      example:
        type: "string|null"

  dictionary_meaning:
    fields:
      partOfSpeech:
        type: "string"
        examples:
          - "noun"
          - "verb"
          - "adjective"
          - "adverb"
          - "phrase"
      transitivity:
        type: "string|null"
        enum:
          - "transitive"
          - "intransitive"
          - "both"
          - null
      countability:
        type: "string|null"
        enum:
          - "countable"
          - "uncountable"
          - "both"
          - null
      definitionEn:
        type: "string"
      translationZhTw:
        type: "string"
      usageContext:
        type: "string|null"
      register:
        type: "string|null"
        examples:
          - "formal"
          - "informal"
          - "neutral"
          - "slang"
      examples:
        type: "array"
        item:
          type: "DictionaryExample"

  dictionary_example:
    fields:
      english:
        type: "string"
      traditionalChinese:
        type: "string"
      highlightedTerm:
        type: "string|null"

  word_forms:
    fields:
      base:
        type: "string|null"
      thirdPersonSingular:
        type: "string|null"
      presentParticiple:
        type: "string|null"
      past:
        type: "string|null"
      pastParticiple:
        type: "string|null"
      plural:
        type: "string|null"
      comparative:
        type: "string|null"
      superlative:
        type: "string|null"

  favorite_word:
    fields:
      id:
        type: "string"
        format: "UUID"
      word:
        type: "string"
      normalizedWord:
        type: "string"
      query:
        type: "string"
      phonetic:
        type: "string|null"
      primaryPartOfSpeech:
        type: "string|null"
      primaryTranslationZhTw:
        type: "string|null"
      savedEntry:
        type: "DictionaryEntry"
        description: >
          儲存完整查詢結果，讓使用者在離線狀態下仍可閱讀已收藏內容。
      savedAt:
        type: "ISO-8601 datetime"
      updatedAt:
        type: "ISO-8601 datetime"

  llm_settings:
    fields:
      provider:
        type: "string"
        enum:
          - "gemini"
          - "openai"
      model:
        type: "string"
      customModel:
        type: "string|null"
      hasApiKey:
        type: "boolean"
      outputLanguage:
        type: "string"
        default: "zh-TW"
      learnerLevel:
        type: "string"
        default: "intermediate"
      englishVariant:
        type: "string"
        default: "both"

local_storage:
  favorites_file:
    filename: "favorites.json"
    directory: "Application Documents Directory"
    encoding: "UTF-8"
    root_format:
      schemaVersion: "1.0"
      updatedAt: "ISO-8601 datetime"
      favorites: "array<FavoriteWord>"
    write_strategy:
      - "讀取現有 JSON"
      - "建立記憶體副本"
      - "修改副本"
      - "寫入暫存檔"
      - "原子性替換正式檔案"
    duplicate_key: "normalizedWord"
    corruption_handling:
      - "保留損壞檔案備份"
      - "建立空白 favorites.json"
      - "顯示資料復原警告"

  secure_storage:
    purpose: "保存使用者 API Key"
    implementation: "flutter_secure_storage"
    cloud_sync: false
    log_value: false

  preferences:
    implementation: "shared_preferences"
    data:
      - "provider"
      - "model"
      - "theme"
      - "outputLanguage"
      - "learnerLevel"
      - "englishVariant"

llm_providers:
  gemini:
    display_name: "Google Gemini"
    default_model: "gemini-2.5-flash"
    authentication:
      type: "API Key"
      storage: "Secure Storage"
    client_strategy: "GeminiProviderClient"
    request_requirements:
      - "HTTPS"
      - "JSON response"
      - "逾時處理"
      - "錯誤碼轉換"

  openai:
    display_name: "OpenAI"
    default_model: "產品設定的推薦模型"
    authentication:
      type: "API Key"
      storage: "Secure Storage"
    client_strategy: "OpenAIProviderClient"
    request_requirements:
      - "HTTPS"
      - "Structured JSON"
      - "逾時處理"
      - "錯誤碼轉換"

  provider_interface:
    name: "LLMProviderClient"
    methods:
      validateApiKey:
        input:
          - "apiKey"
          - "model"
        output: "ValidationResult"
      lookupDictionary:
        input:
          - "query"
          - "settings"
        output: "DictionaryEntry"

security:
  api_key:
    user_owned_key:
      storage: "iOS Keychain / Android Keystore-backed storage"
      package: "flutter_secure_storage"
      direct_api_call: true
      send_to_app_backend: false
      expose_in_ui: false
      mask_in_ui: true

    developer_owned_key:
      recommendation: >
        若未來提供開發者自己的免費查詢額度，
        API Key 必須存於後端環境變數，再由 App 呼叫後端。
        絕對不能把開發者 API Key 打包在 Flutter App。
      frontend_environment_variable_allowed: false

  requirements:
    - "不得記錄 Authorization Header"
    - "不得記錄完整 API Key"
    - "不得把 API Key 寫入 crash report"
    - "不得把 API Key 存入 favorites.json"
    - "所有 API 請求使用 HTTPS"
    - "使用者可以刪除 API Key"
    - "API Key 輸入框關閉自動修正和文字建議"

error_handling:
  cases:
    missing_api_key:
      message: "尚未設定 API Key，請先前往設定。"
      action:
        - "顯示前往設定按鈕"
    invalid_api_key:
      message: "API Key 無效，請檢查後重新輸入。"
    unsupported_model:
      message: "目前模型不可用，請在設定中選擇其他模型。"
    quota_exceeded:
      message: "API 使用額度已用完，請檢查供應商帳戶。"
    rate_limited:
      message: "查詢過於頻繁，請稍後再試。"
    no_network:
      message: "目前無法連線，請檢查網路。"
    timeout:
      message: "查詢逾時，請重新嘗試。"
    malformed_llm_json:
      message: "AI 回傳格式不正確，請重新查詢。"
      internal_action:
        - "執行一次 JSON 修復或重試"
    provider_server_error:
      message: "模型服務暫時無法使用，請稍後再試。"
    favorite_file_error:
      message: "無法存取我的單字清單。"

loading_and_state:
  dictionary_status:
    states:
      - "idle"
      - "validating"
      - "loading"
      - "success"
      - "error"
  favorite_status:
    states:
      - "notFavorite"
      - "favorite"
      - "saving"
      - "removing"
      - "error"
  settings_status:
    states:
      - "idle"
      - "testing"
      - "saving"
      - "success"
      - "error"

business_rules:
  - id: "BR-001"
    rule: "沒有查詢結果時，收藏星星必須停用。"
  - id: "BR-002"
    rule: "收藏識別以 normalizedWord 為準，避免 Apple 與 apple 重複。"
  - id: "BR-003"
    rule: "中文查詢有多個英文對應字時，主要結果只能選一個，其他列入 alternatives。"
  - id: "BR-004"
    rule: "使用者切換模型供應商後，下一次查詢立即使用新設定。"
  - id: "BR-005"
    rule: "查詢期間禁止重複送出相同請求。"
  - id: "BR-006"
    rule: "LLM 回傳必須經 Schema 驗證後才能顯示及收藏。"
  - id: "BR-007"
    rule: "刪除 API Key 不得刪除已收藏單字。"
  - id: "BR-008"
    rule: "收藏完整結果後，即使離線也可以查看該收藏內容。"
  - id: "BR-009"
    rule: "AI 產生內容不得宣稱為任何商業字典的正式內容。"
  - id: "BR-010"
    rule: "模型清單應可以透過 App 更新或設定檔調整，不應永久寫死。"

privacy_and_compliance:
  user_notice:
    - "查詢內容會傳送至使用者所選擇的 LLM 供應商。"
    - "API Key 僅儲存在使用者裝置的安全儲存區。"
    - "App 不會將 API Key 上傳到開發者伺服器。"
    - "AI 產生內容可能包含錯誤，重要內容應交叉確認。"
  privacy_policy_required: true
  app_store_disclosures:
    - "是否收集查詢紀錄"
    - "是否使用分析工具"
    - "是否使用 Crash Reporting"
    - "資料是否傳給 OpenAI 或 Google"
    - "是否有帳號功能"
  recommended_mvp_policy:
    account_required: false
    advertising: false
    analytics: false
    cloud_sync: false

accessibility:
  requirements:
    - "所有 IconButton 提供 tooltip 或 semanticLabel"
    - "支援系統字體放大"
    - "文字與背景符合可讀性對比"
    - "不得只用顏色表示收藏狀態"
    - "查詢結果文字可以選取"
    - "Loading 與錯誤狀態提供文字說明"

testing:
  unit_tests:
    - "DictionaryEntry JSON 解析"
    - "LLM Schema 驗證"
    - "normalizedWord 正規化"
    - "收藏新增與移除"
    - "重複收藏防止"
    - "Settings Repository"
    - "API 錯誤轉換"
  widget_tests:
    - "搜尋欄輸入與送出"
    - "查詢中按鈕停用"
    - "星星狀態切換"
    - "設定欄位驗證"
    - "我的清單空白狀態"
  integration_tests:
    - "Gemini 查詢流程"
    - "OpenAI 查詢流程"
    - "設定 API Key 後執行查詢"
    - "中文輸入轉換為英文單字"
    - "收藏後重新啟動 App 仍然存在"
    - "收藏項目刪除"
    - "無網路與逾時處理"
  device_tests:
    android:
      - "不同 Android 版本"
      - "不同螢幕尺寸"
      - "返回鍵行為"
    ios:
      - "iPhone 小螢幕"
      - "iPhone 大螢幕"
      - "Keychain 儲存"
      - "深色模式"

mvp_scope:
  included:
    - "英文單字查詢"
    - "英文片語查詢"
    - "中文轉英文單字"
    - "Gemini Provider"
    - "OpenAI Provider"
    - "模型選擇"
    - "使用者 API Key"
    - "三個主要 UI"
    - "本機 JSON 收藏"
    - "刪除收藏"
    - "深色模式"
    - "基本錯誤處理"
  excluded:
    - "使用者帳號"
    - "雲端同步"
    - "廣告"
    - "訂閱付款"
    - "傳統字典資料庫"
    - "社群功能"
    - "跨裝置同步"
    - "後端保存使用者 API Key"

future_features:
  - "TTS 美式與英式發音"
  - "歷史查詢"
  - "單字標籤與分類"
  - "單字測驗"
  - "間隔重複學習"
  - "匯入與匯出收藏 JSON"
  - "分享單字卡"
  - "Web 版本"
  - "相機 OCR 查字"
  - "例句難度切換"
  - "離線查看已收藏結果"

acceptance_criteria:
  dictionary_screen:
    - "使用者可以輸入中文或英文並送出查詢。"
    - "有效 API Key 下可以取得結構化字典結果。"
    - "查詢結果至少包含英文單字、音標、詞性、中文翻譯、英文解釋及例句。"
    - "使用者可以用星星加入或移除收藏。"
    - "設定與清單按鈕可以正確導向對應 UI。"
  settings_screen:
    - "使用者可以選擇 Gemini 或 OpenAI。"
    - "使用者可以選擇或輸入模型名稱。"
    - "API Key 儲存在 Secure Storage。"
    - "重新開啟 App 後設定仍然存在。"
    - "使用者可以測試、更新和刪除 API Key。"
  favorites_screen:
    - "收藏內容保存在手機 favorites.json。"
    - "App 重新啟動後收藏仍然存在。"
    - "使用者可以查看、搜尋和刪除收藏。"
    - "點選收藏可以回到字典畫面查看完整內容。"

implementation_phases:
  phase_1:
    name: "專案基礎"
    tasks:
      - "建立 Flutter 專案"
      - "建立三個 Route"
      - "設定 Riverpod"
      - "建立共用 Theme"
      - "建立資料模型"
  phase_2:
    name: "設定與安全儲存"
    tasks:
      - "完成 SettingsScreen"
      - "完成 SharedPreferences Repository"
      - "完成 Secure Storage Repository"
      - "完成供應商與模型設定"
  phase_3:
    name: "LLM 字典查詢"
    tasks:
      - "建立 LLMProviderClient 介面"
      - "實作 Gemini Client"
      - "實作 OpenAI Client"
      - "建立嚴格 JSON Prompt"
      - "實作 Schema 驗證"
      - "完成 DictionaryScreen"
  phase_4:
    name: "收藏功能"
    tasks:
      - "建立 favorites.json Repository"
      - "完成收藏新增、移除與防重複"
      - "完成 FavoritesScreen"
      - "支援離線查看收藏結果"
  phase_5:
    name: "測試與上架"
    tasks:
      - "單元測試"
      - "Android 實機測試"
      - "iOS 實機測試"
      - "建立隱私權政策"
      - "準備 App Icon 與商店截圖"
      - "Google Play 測試與上架"
      - "TestFlight 測試與 App Store 上架"