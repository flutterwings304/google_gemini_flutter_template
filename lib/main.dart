import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "lib/.env");

  Gemini.init(apiKey: dotenv.env["GOOGLE_API_KEY"].toString());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Gemini',
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          cardTheme: CardTheme(color: Colors.lightGreenAccent.shade100)),
      home: const MyGeminiSearchScreen(),
    );
  }
}

class MyGeminiSearchScreen extends StatefulWidget {
  const MyGeminiSearchScreen({super.key});

  @override
  State<MyGeminiSearchScreen> createState() => _MyGeminiSearchScreenState();
}

class _MyGeminiSearchScreenState extends State<MyGeminiSearchScreen> {
  final ImagePicker picker = ImagePicker();
  final controller = TextEditingController();
  final gemini = Gemini.instance;
  String? searchedText, result;

  bool loading = false;
  bool isTextWithImage = false;
  Uint8List? selectedImage;

  @override
  Widget build(BuildContext context) {
    print("loading $loading");
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flutter Gemini"),
      ),
      body: Column(
        children: [
          //Radio to select between different type of search
          Row(
            children: [
              Radio(
                  value: false,
                  groupValue: isTextWithImage,
                  onChanged: (val) {
                    setState(() {
                      isTextWithImage = val ?? false;
                    });
                  }),
              const Text("Search with Text"),
              Radio(
                  value: true,
                  groupValue: isTextWithImage,
                  onChanged: (val) {
                    setState(() {
                      isTextWithImage = val ?? false;
                    });
                  }),
              const Text("Search with Text and Image")
            ],
          ),
          //To show text that we have search for
          if (searchedText != null)
            MaterialButton(
                color: Colors.green.shade200,
                onPressed: () {
                  setState(() {
                    searchedText = null;
                    result = null;
                  });
                },
                child: Text(
                  'Search: $searchedText',
                  style: const TextStyle(color: Colors.white),
                )),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    //Loader when gemini is searching for result
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : result != null
                            ? Markdown(
                                data: result!,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                              )
                            : const Center(
                                child: Text('Search something!'),
                              ),
                  ),
                  if (selectedImage != null)
                    Expanded(
                      flex: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.memory(
                          selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    hintText: 'Write Something...',
                    border: InputBorder.none,
                  ),
                  onTapOutside: (event) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                )),
                if (isTextWithImage)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    //Select image from device
                    child: IconButton(
                        onPressed: () async {
                          final ImagePicker picker =
                              ImagePicker(); //To select Image from device
                          // Capture a photo.
                          final XFile? photo = await picker.pickImage(
                              source: ImageSource.camera);

                          if (photo != null) {
                            photo.readAsBytes().then((value) => setState(() {
                                  selectedImage = value;
                                }));
                          }
                        },
                        icon: const Icon(Icons.file_copy_outlined)),
                  ),
                // Send the typed the search to gemini
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          if (isTextWithImage) {
                            if (selectedImage != null) {
                              searchedText = controller.text;
                              controller.clear();
                              loading = true;
                              setState(() {});
                              gemini
                                  .textAndImage(
                                      text: searchedText!,
                                      image: selectedImage!)
                                  .then((value) {
                                result = value?.content?.parts?.last.text;
                                loading = false;
                                   setState(() {});
                              });
                            } else {
                              Fluttertoast.showToast(
                                  msg: "Please select picture");
                            }
                          } else {
                            searchedText = controller.text;
                            controller.clear();
                            loading = true;
                            setState(() {});
                            gemini.text(searchedText!).then((value) {
                              print(value?.content?.parts?.toString());
                              result = value?.content?.parts?.last.text;
                              loading = false;
                                    setState(() {});
                            });
                          }
                        } else {
                          Fluttertoast.showToast(msg: "Please enter something");
                        }
                      },
                      icon: const Icon(Icons.send_rounded)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
