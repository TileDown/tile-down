import TileCore

extension TileKit.ServiceForm.Renderer {
    static let defaultCSS = """
    .td-service-form {
      display: grid;
      gap: 1rem;
      max-width: 42rem;
    }

    .td-service-form__form {
      display: grid;
      gap: 0.875rem;
    }

    .td-service-form__field,
    .td-service-form__result {
      display: grid;
      gap: 0.375rem;
    }

    .td-service-form__label,
    .td-service-form__result-label {
      color: #1f2937;
      font-weight: 650;
    }

    .td-service-form__control {
      align-items: center;
      display: flex;
      gap: 0.5rem;
    }

    .td-service-form input,
    .td-service-form textarea,
    .td-service-form select {
      border: 1px solid #9ca3af;
      border-radius: 6px;
      color: #111827;
      font: inherit;
      min-height: 2.5rem;
      padding: 0.5rem 0.625rem;
      width: 100%;
    }

    .td-service-form input[type="checkbox"] {
      min-height: 1rem;
      width: auto;
    }

    .td-service-form input[aria-invalid="true"],
    .td-service-form textarea[aria-invalid="true"],
    .td-service-form select[aria-invalid="true"] {
      border-color: #b91c1c;
    }

    .td-service-form__message {
      color: #b91c1c;
      font-size: 0.875rem;
      min-height: 1.25rem;
    }

    .td-service-form__submit {
      background: #0f766e;
      border: 0;
      border-radius: 6px;
      color: #ffffff;
      cursor: pointer;
      font: inherit;
      font-weight: 650;
      min-height: 2.5rem;
      padding: 0.5rem 0.875rem;
      width: fit-content;
    }

    .td-service-form__states {
      color: #374151;
      min-height: 1.5rem;
    }

    .td-service-form__results {
      display: grid;
      gap: 0.75rem;
      margin: 0;
    }

    .td-service-form__result-value {
      margin: 0;
    }

    .td-service-form__unit {
      color: #4b5563;
      white-space: nowrap;
    }
    """

    static let defaultJavaScript = """
    (() => {
      const configScripts = document.querySelectorAll("script[data-td-config]");

      function findByAttribute(root, selector, attribute, value) {
        return Array.from(root.querySelectorAll(selector)).find((element) => {
          return element.getAttribute(attribute) === value;
        }) || null;
      }

      function setState(root, state, message) {
        root.querySelectorAll("[data-td-state]").forEach((element) => {
          const active = element.getAttribute("data-td-state") === state;
          element.hidden = !active;
          if (active && message) {
            element.textContent = message;
          }
        });
      }

      function setFieldMessage(root, name, message) {
        const messageElement = findByAttribute(
          root,
          "[data-td-field-message]",
          "data-td-field-message",
          name
        );
        const input = findByAttribute(root, "[name]", "name", name);
        if (messageElement) {
          messageElement.textContent = message || "";
        }
        if (input) {
          if (message) {
            input.setAttribute("aria-invalid", "true");
          } else {
            input.removeAttribute("aria-invalid");
          }
        }
      }

      function readValue(form, field) {
        const control = form.elements.namedItem(field.name);
        if (!control) {
          return "";
        }
        if (field.schemaType === "boolean") {
          return Boolean(control.checked);
        }
        if (field.schemaType === "number" || field.schemaType === "integer") {
          return control.value === "" ? "" : Number(control.value);
        }
        return control.value;
      }

      function validateField(value, field) {
        const missing = value === "" || value === null || value === undefined;
        if (field.required && (missing || value === false)) {
          return "Required.";
        }
        if (missing) {
          return "";
        }
        if (field.pattern && typeof value === "string") {
          const matches = new RegExp(field.pattern).test(value);
          if (!matches) {
            return "Invalid format.";
          }
        }
        if (typeof value === "number" && Number.isNaN(value)) {
          return "Enter a number.";
        }
        if (typeof value !== "number") {
          return "";
        }
        if (field.minimum !== null && field.minimum !== undefined && value < field.minimum) {
          return `Must be at least ${field.minimum}.`;
        }
        if (
          field.exclusiveMinimum !== null &&
          field.exclusiveMinimum !== undefined &&
          value <= field.exclusiveMinimum
        ) {
          return `Must be greater than ${field.exclusiveMinimum}.`;
        }
        if (field.maximum !== null && field.maximum !== undefined && value > field.maximum) {
          return `Must be at most ${field.maximum}.`;
        }
        if (
          field.exclusiveMaximum !== null &&
          field.exclusiveMaximum !== undefined &&
          value >= field.exclusiveMaximum
        ) {
          return `Must be less than ${field.exclusiveMaximum}.`;
        }
        return "";
      }

      function payloadFromForm(root, form, config) {
        const payload = {};
        let valid = true;
        config.inputFields.forEach((field) => {
          const value = readValue(form, field);
          const message = validateField(value, field);
          setFieldMessage(root, field.name, message);
          if (message) {
            valid = false;
          }
          payload[field.name] = value;
        });
        return { payload, valid };
      }

      function formatValue(value, field) {
        if (value === null || value === undefined) {
          return "";
        }
        const format = field.outputFormat || field.semanticType;
        if (format === "decimal" || format === "positiveDecimal") {
          const number = Number(value);
          if (!Number.isNaN(number)) {
            return new Intl.NumberFormat().format(number);
          }
        }
        if (typeof value === "boolean") {
          return value ? "Yes" : "No";
        }
        return String(value);
      }

      function renderResults(root, config, data) {
        config.outputFields.forEach((field) => {
          const target = findByAttribute(
            root,
            "[data-td-output-value]",
            "data-td-output-value",
            field.name
          );
          if (target) {
            target.textContent = formatValue(data[field.name], field);
          }
        });
      }

      configScripts.forEach((script) => {
        const root = script.closest("[data-td-service-form-root]");
        if (!root || root.getAttribute("data-td-bound") === "true") {
          return;
        }
        root.setAttribute("data-td-bound", "true");

        const config = JSON.parse(script.textContent || "{}");
        const form = root.querySelector("[data-td-service-form]");
        if (!form) {
          return;
        }

        form.addEventListener("submit", async (event) => {
          event.preventDefault();
          const result = payloadFromForm(root, form, config);
          if (!result.valid) {
            setState(root, "validation");
            return;
          }

          setState(root, "loading");
          try {
            const response = await fetch(config.endpoint, {
              method: config.method,
              headers: {
                "Accept": "application/json",
                "Content-Type": "application/json"
              },
              body: JSON.stringify(result.payload)
            });
            if (!response.ok) {
              setState(root, "unavailable", `Service returned ${response.status}.`);
              return;
            }
            const data = await response.json();
            renderResults(root, config, data);
            setState(root, "success");
          } catch (error) {
            const message = error instanceof Error ? error.message : "Request failed.";
            setState(root, "error", message);
          }
        });
      });
    })();
    """
}
