/// Build flavors supported by this template.
enum Environment {
  dev,
  prod;

  static Environment fromName(String? name) {
    if (name == 'dev') return Environment.dev;
    return Environment.prod;
  }
}
