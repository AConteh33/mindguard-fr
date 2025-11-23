import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  PageController controller = PageController();
  int currentPage = 0;

  @override
  void initState() {
    controller.addListener(() {
      setState(() {
        currentPage = controller.page?.round() ?? 0;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: PageView(
          controller: controller,
          children: [
            IntroPageTemplate(
              activePage: currentPage,
              title: "Bienvenue sur MindGuard",
              subtitle: "Votre application de bien-être numérique",
              description: "Suivez votre humeur, gérez votre temps d'écran et améliorez votre équilibre digital.",
              imagePath: "Backgrounds/Spline.png", // Using existing asset as placeholder
            ),
            IntroPageTemplate(
              activePage: currentPage,
              title: "Suivi de votre humeur",
              subtitle: "Comprenez vos émotions au quotidien",
              description: "Enregistrez votre humeur quotidiennement et visualisez vos tendances émotionnelles.",
              imagePath: "Backgrounds/Spline.png", // Using existing asset as placeholder
            ),
            IntroPageTemplate(
              activePage: currentPage,
              title: "Mode Focus",
              subtitle: "Améliorez votre concentration",
              description: "Activer le mode focus pour vous concentrer sur vos tâches sans distractions.",
              imagePath: "Backgrounds/Spline.png", // Using existing asset as placeholder
            ),
          ],
        ),
      ),
    );
  }
}

class IntroPageTemplate extends StatelessWidget {
  final int activePage;
  final String imagePath;
  final String title;
  final String subtitle;
  final String description;

  const IntroPageTemplate({
    super.key,
    required this.activePage,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                image: DecorationImage(
                  fit: BoxFit.contain, // Changed to contain instead of fill
                  image: AssetImage(
                    imagePath,
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            constraints: BoxConstraints(minWidth: size.height * 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24.0,
                    height: 1.3,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 16.0,
                    height: 1.3,
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14.0,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 20),
                PageIndicator(activePage: activePage),
                SizedBox(height: 30),
                ShadButton(
                  onPressed: () {
                    // Navigate to role selection
                    context.go('/role-selection');
                  },
                  child: const Text("Commencer"),
                )
              ],
            ),
          ),
          Center(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              runAlignment: WrapAlignment.center,
              children: [
                Text(
                  "Vous avez déjà un compte?",
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.go('/login');
                  },
                  child: Text(
                    "Se connecter",
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 15),
        ],
      ),
    );
  }
}

class PageIndicator extends StatelessWidget {
  final int activePage;
  const PageIndicator({super.key, required this.activePage});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => Container(
          width: index == activePage ? 22.0 : 8.0,
          height: 8.0,
          margin: EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(index == activePage ? 10.0 : 50.0),
            color: index == activePage
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}