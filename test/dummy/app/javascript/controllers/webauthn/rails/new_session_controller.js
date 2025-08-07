import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["credentialHiddenInput"];

  async create() {
    try {
      const optionsResponse = await fetch("/webauthn-rails/session/get_options", {
        method: "POST",
        body: new FormData(this.element),
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")
        },
      });

      const optionsJson = await optionsResponse.json();

      if (optionsResponse.ok) {
        const credentialOptions = PublicKeyCredential.parseRequestOptionsFromJSON(optionsJson);
        const credential = await navigator.credentials.get({ publicKey: credentialOptions });

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
