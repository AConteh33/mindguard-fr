import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/permission_service.dart';
import '../widgets/permission/permission_wrapper.dart';

class VideoTherapyScreen extends StatefulWidget {
  const VideoTherapyScreen({super.key});

  @override
  State<VideoTherapyScreen> createState() => _VideoTherapyScreenState();
}

class _VideoTherapyScreenState extends State<VideoTherapyScreen> {
  final PermissionService _permissionService = PermissionService();

  @override
  void initState() {
    super.initState();
    _permissionService.setContext(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thérapie Vidéo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _permissionService.showPermissionStatusDialog(),
            tooltip: 'Vérifier les permissions',
          ),
        ],
      ),
      body: MultiPermissionWrapper(
        permissions: [
          Permission.camera,
          Permission.microphone,
        ],
        fallback: const VideoTherapyPermissionFallback(),
        child: const VideoTherapyContent(),
      ),
    );
  }
}

class VideoTherapyContent extends StatelessWidget {
  const VideoTherapyContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Preview Area
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam,
                    size: 48,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aperçu de la caméra',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Session Controls
          Text(
            'Contrôles de session',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Start video session
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Commencer'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Schedule session
                  },
                  icon: const Icon(Icons.schedule),
                  label: const Text('Planifier'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Features
          Text(
            'Fonctionnalités disponibles',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ...List.generate(4, (index) {
            final features = [
              {'icon': Icons.mic, 'title': 'Enregistrement audio', 'description': 'Capture votre voix pendant les exercices'},
              {'icon': Icons.camera_alt, 'title': 'Analyse faciale', 'description': 'Suivi des expressions émotionnelles'},
              {'icon': Icons.screenshot, 'title': 'Captures d\'écran', 'description': 'Sauvegarde des moments importants'},
              {'icon': Icons.record_voice_over, 'title': 'Exercices vocaux', 'description': 'Pratique avec feedback audio'},
            ];
            
            final feature = features[index];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  feature['icon'] as IconData,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(feature['title'] as String),
                subtitle: Text(feature['description'] as String),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Handle feature tap
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class VideoTherapyPermissionFallback extends StatelessWidget {
  const VideoTherapyPermissionFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Permissions requises',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'La thérapie vidéo nécessite l\'accès à votre caméra et à votre microphone.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PermissionCheckScreen(
                    requiredPermissions: [
                      Permission.camera,
                      Permission.microphone,
                    ],
                    title: 'Permissions Thérapie Vidéo',
                    description: 'Autorisez l\'accès à votre caméra et microphone pour commencer les sessions de thérapie vidéo.',
                  ),
                ),
              );
            },
            child: const Text('Vérifier les permissions'),
          ),
        ],
      ),
    );
  }
}
