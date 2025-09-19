import { Controller } from "@hotwired/stimulus";
import { create as createWebAuthnJSON, get as getWebAuthnJSON } from "@github/webauthn-json/browser-ponyfill";

export default class extends Controller {
  static targets = ["credentialHiddenInput", "submitButton"];
  static values = { optionsUrl: String }

  connect() {
    this.submitButtonTarget.disabled = false;
  }

  async create() {
    try {
      const optionsResponse = await fetch(this.optionsUrlValue, {
        method: "POST",
        body: new FormData(this.element),
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")
        },
      });

      const optionsJson = await optionsResponse.json();
      if (optionsResponse.ok) {
        const credentialOptions = PublicKeyCredential.parseCreationOptionsFromJSON(optionsJson);
        const credential = await createWebAuthnJSON({ publicKey: credentialOptions });

        this.credentialHiddenInputTarget.value = JSON.stringify(credential);

        this.element.submit();
      } else {
        alert(optionsJson.errors?.[0] || "Unknown error");
      }
    } catch (error) {
      alert(error.message || error);
    }
  }

  async get() {
    try {
      const optionsResponse = await fetch(this.optionsUrlValue, {
        method: "POST",
        body: new FormData(this.element),
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")
        },
      });

      const optionsJson = await optionsResponse.json();

      if (optionsResponse.ok) {
        const credentialOptions = PublicKeyCredential.parseRequestOptionsFromJSON(optionsJson);
        const credential = await getWebAuthnJSON({ publicKey: credentialOptions });

        this.credentialHiddenInputTarget.value = JSON.stringify(credential);

        this.element.submit();
      } else {
        alert(optionsJson.errors?.[0] || "Unknown error");
      }
    } catch (error) {
      alert(error.message || error);
    }
  }
}
