// Grammar-aware Madlib-style Random Sentence Generator (screen-safe + random colors)
PFont font;
int fontSize = 48;
int lastChangeTime = 0;
int interval = 5000; // 5 seconds

String[] adjectives;
String[] prepositions;
String[] adverbs;
String[] determiners;
String[] nouns;
String[] particles;
String[] verbsSingular;
String[] verbsPlural;

String currentSentence = "";

color bgColor = color(255);
color txtColor = color(0);

void setup() {
  size(1000, 600);
  smooth();
  textAlign(CENTER, CENTER);

  adjectives = loadStrings("top_english_adjs_lower_50000.txt");
  prepositions = loadStrings("top_english_adps_lower_500.txt");
  adverbs = loadStrings("top_english_advs_lower_10000.txt");
  determiners = loadStrings("top_english_dets_lower_500.txt");
  nouns = loadStrings("top_english_nouns_lower_50000.txt");
  particles = loadStrings("top_english_prts_lower_500.txt");

  String[] allVerbs = loadStrings("top_english_verbs_lower_50000.txt");
  verbsSingular = new String[allVerbs.length/2];
  verbsPlural = new String[allVerbs.length/2];
  for (int i = 0; i < allVerbs.length; i++) {
    if (i % 2 == 0) verbsSingular[i/2] = allVerbs[i];
    else verbsPlural[i/2] = allVerbs[i];
  }

  font = createFont("Arial", fontSize);
  textFont(font);
  generateSentence();
}

void draw() {
  background(bgColor);
  fill(txtColor);

  if (millis() - lastChangeTime > interval) {
    generateSentence();
    lastChangeTime = millis();
  }

  float maxWidth = width * 0.9;
  float maxHeight = height * 0.9;
  float testFontSize = fontSize;
  textFont(font);
  textSize(testFontSize);

  while (textHeight(currentSentence, maxWidth, testFontSize) > maxHeight && testFontSize > 12) {
    testFontSize -= 2;
    textSize(testFontSize);
  }

  drawCenteredText(currentSentence, width/2, height/2, maxWidth);
}

void generateSentence() {
  // Random font & size
  String[] fonts = PFont.list();
  String randomFont = fonts[int(random(fonts.length))];
  fontSize = max(12, fontSize + int(random(-12, 13)));
  font = createFont(randomFont, fontSize);
  textFont(font);

  // Randomize colors
  bgColor = color(random(255), random(255), random(255));
  txtColor = color(random(255), random(255), random(255));

  String det1 = randomFrom(determiners);
  String adj1 = randomFrom(adjectives);
  String noun1 = randomFrom(nouns);
  boolean plural = isPluralNoun(det1, noun1);
  String verb = plural ? randomFrom(verbsPlural) : randomFrom(verbsSingular);
  String adv = randomFrom(adverbs);
  String prep = randomFrom(prepositions);
  String det2 = randomFrom(determiners);
  String adj2 = randomFrom(adjectives);
  String noun2 = randomFrom(nouns);
  String particle = randomParticle();

  currentSentence = capitalize(det1) + " " + adj1 + " " + noun1 + " " +
                    adv + " " + verb + " " + prep + " " + det2 + " " + adj2 + " " + noun2 +
                    particle + ".";
}

boolean isPluralNoun(String det, String noun) {
  det = det.toLowerCase();
  if (det.equals("some") || det.equals("these") || det.equals("those")) return true;
  if (noun.endsWith("s")) return true;
  return false;
}

void drawCenteredText(String txt, float x, float y, float maxWidth) {
  String[] words = split(txt, ' ');
  String line = "";
  String[] lines = {};
  for (int i = 0; i < words.length; i++) {
    String testLine = line + (line.equals("") ? "" : " ") + words[i];
    if (textWidth(testLine) > maxWidth) {
      lines = append(lines, line);
      line = words[i];
    } else {
      line = testLine;
    }
  }
  lines = append(lines, line);

  float lineHeight = textAscent() + textDescent();
  float totalHeight = lines.length * lineHeight * 1.2;
  float startY = y - totalHeight/2 + lineHeight/2;

  for (int i = 0; i < lines.length; i++) {
    text(lines[i], x, startY + i * lineHeight * 1.2);
  }
}

float textHeight(String txt, float maxWidth, float size) {
  textSize(size);
  String[] words = split(txt, ' ');
  String line = "";
  String[] lines = {};
  for (int i = 0; i < words.length; i++) {
    String testLine = line + (line.equals("") ? "" : " ") + words[i];
    if (textWidth(testLine) > maxWidth) {
      lines = append(lines, line);
      line = words[i];
    } else {
      line = testLine;
    }
  }
  lines = append(lines, line);
  float lineHeight = textAscent() + textDescent();
  return lines.length * lineHeight * 1.2;
}

String randomFrom(String[] list) {
  return list[int(random(list.length))];
}

String randomParticle() {
  if (random(1) > 0.5) return " " + randomFrom(particles);
  else return "";
}

String capitalize(String str) {
  if (str.length() > 0) return str.substring(0,1).toUpperCase() + str.substring(1);
  else return str;
}
