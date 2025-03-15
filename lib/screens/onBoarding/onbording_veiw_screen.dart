import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../Components/color.dart';
import 'onboarding_items.dart';
//import 'package:url_launcher/url_launcher.dart';
import '../WebView/webview_screen.dart';
//import 'package:cached_network_image/cached_network_image.dart';


class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  _OnboardingViewState createState() => _OnboardingViewState();
}


class _OnboardingViewState extends State<OnboardingView> {

  final controller = OnboardingItems();
  final PageController pageController = PageController();
  bool isLastPage = false;


  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isOnboarded = prefs.getBool("onboarding") ?? false;
    if (isOnboarded && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WebViewPage(url: "https://60c2-102-88-108-224.ngrok-free.app/auth/students/login")),
      );
    }
  }

  @override
  void dispose() {
    pageController.dispose(); // Free memory
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      bottomSheet: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),
        child: isLastPage? getStarted() : navigationControls(),
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        child: PageView.builder(
          onPageChanged: (index)=> setState(()=> isLastPage = controller.items.length-1 == index),
          itemCount: controller.items.length,
          controller: pageController,
          itemBuilder: (context,index) => buildOnboardingPage(index),
        ),
      ),
    );
  }

  Widget navigationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () => pageController.jumpToPage(controller.items.length - 1),
          child: const Text("Skip"),
        ),
        SmoothPageIndicator(
          controller: pageController,
          count: controller.items.length,
          onDotClicked: (index) => pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeIn,
          ),
          effect: const WormEffect(
            dotHeight: 12,
            dotWidth: 12,
            activeDotColor: primaryColor,
          ),
        ),
        TextButton(
          onPressed: () => pageController.nextPage(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeIn,
          ),
          child: const Text("Next"),
        ),
      ],
    );
  }


  Widget buildOnboardingPage(int index) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        //CachedNetworkImage(
        //  imageUrl: controller.items[index].image,
        //  placeholder: (context, url) => const CircularProgressIndicator(),
        //  errorWidget: (context, url, error) => const Icon(Icons.error),
        //  //width: 200,
        //  //height: 200,
        //),
        Image.asset(
          controller.items[index].image,
          width: 200,
          height: 200,
          fit: BoxFit.contain, // Ensures the image fits properly
        ),
        const SizedBox(height: 15),
        Text(
          controller.items[index].title,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        Text(
          controller.items[index].descriptions,
          style: const TextStyle(color: Colors.grey, fontSize: 17),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }


  //Get started button

  Widget getStarted(){
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: primaryColor
      ),
      width: MediaQuery.of(context).size.width * .9,
      height: 55,
      child: TextButton(
          onPressed: ()async{
            final pres = await SharedPreferences.getInstance();
            pres.setBool("onboarding", true);

            //After we press get started button this onboarding value become true
            // same key
            if(!mounted)return;
            // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Home()));
            const url = "https://60c2-102-88-108-224.ngrok-free.app/auth/students/login";
            Navigator.push(
              context,
              MaterialPageRoute(
                // WebViewPage(url: url)  
                builder: (context) => WebViewPage(url: url),
              ),
            );
          },
          child: const Text("Get started",style: TextStyle(color: Colors.white),)),
    );
  }
}
