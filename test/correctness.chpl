use UnitTest;
import Base64;
import List.list;

record testCase {
  var originalHex: bytes;
  var base64Standard: bytes;
  var base64UrlSafe: bytes;
}
private proc hexToBytes(hex: bytes): bytes {
  var result: bytes;
  for i in 0..#(hex.size / 2) {
    const hi = hexDigit(hex.byte(2*i));
    const lo = hexDigit(hex.byte(2*i + 1));
    result.appendByteValues((hi << 4) | lo);
  }
  return result;
}
private proc hexDigit(ch: uint(8)): uint(8) {
  if ch >= 0x30 && ch <= 0x39 then return (ch - 0x30): uint(8);        // 0-9
  else if ch >= 0x41 && ch <= 0x46 then return (ch - 0x41 + 10): uint(8); // A-F
  else if ch >= 0x61 && ch <= 0x66 then return (ch - 0x61 + 10): uint(8); // a-f
  else return 0;
}

private proc projectHome(): string {
  import Reflection, Path;
  var currentFile = Path.absPath(Reflection.getFileName());
  return Path.dirname(Path.dirname(currentFile));
}

config const csvFile = "";
private var testCases: list(testCase);
proc loadDependencies(test: borrowed Test) throws {
  import Subprocess, IO;
  if testCases.size > 0 then return; // Already loaded

  var reader;
  if csvFile == "" {
    // invoke the generator if no file is provided
    const scriptPath = projectHome() + "/util/generate_test_cases.py";
    var p = Subprocess.spawn(
      ["python3", scriptPath, "-o", "-", "--count=1000", "--max-len=1024"],
      stdout=Subprocess.pipeStyle.pipe, locking=false);
    p.wait();
    reader = p.stdout;
  } else {
    reader = IO.openReader(csvFile);
  }
  // Skip header line
  reader.readLine(bytes);

  var line: bytes;
  while reader.readLine(line) {
    line = line.strip();
    if line.isEmpty() then continue;

    var f = line.split(b",");
    if f.size < 3 then continue;

    testCases.pushBack(new testCase(hexToBytes(f[0]), f[1], f[2]));
  }

  test.assertTrue(true);
}

proc testStandardEncode(test: borrowed Test) throws {
  test.dependsOn(loadDependencies);
  for tc in testCases {
    const encoded = Base64.b64Encode(tc.originalHex);
    test.assertEqual(encoded, tc.base64Standard);
    const encoded2 = Base64.b64Encode(tc.originalHex, urlSafe=false);
    test.assertEqual(encoded2, tc.base64Standard);
    const encoded3 = Base64.b64StandardEncode(tc.originalHex);
    test.assertEqual(encoded3, tc.base64Standard);
  }
}

proc testStandardDecode(test: borrowed Test) throws {
  test.dependsOn(loadDependencies);
  for tc in testCases {
    const decoded = Base64.b64Decode(tc.base64Standard);
    test.assertEqual(decoded, tc.originalHex);
    const decoded2 = Base64.b64Decode(tc.base64Standard, urlSafe=false);
    test.assertEqual(decoded2, tc.originalHex);
    const decoded3 = Base64.b64StandardDecode(tc.base64Standard);
    test.assertEqual(decoded3, tc.originalHex);
  }
}

proc testUrlSafeEncode(test: borrowed Test) throws {
  test.dependsOn(loadDependencies);
  for tc in testCases {
    const encoded = Base64.b64Encode(tc.originalHex, urlSafe=true);
    test.assertEqual(encoded, tc.base64UrlSafe);
    const encoded2 = Base64.b64UrlSafeEncode(tc.originalHex);
    test.assertEqual(encoded2, tc.base64UrlSafe);
  }
}

proc testUrlSafeDecode(test: borrowed Test) throws {
  test.dependsOn(loadDependencies);
  for tc in testCases {
    const decoded = Base64.b64Decode(tc.base64UrlSafe, urlSafe=true);
    test.assertEqual(decoded, tc.originalHex);
    const decoded2 = Base64.b64UrlSafeDecode(tc.base64UrlSafe);
    test.assertEqual(decoded2, tc.originalHex);
  }
}

UnitTest.main();
