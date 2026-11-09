import 'package:flutter/material.dart';

import '../providers/auth_provider.dart';
import '../services/applicant_profile_service.dart';
import 'workspace_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({required this.provider, this.profileService, super.key});
  final AuthProvider provider;
  final ApplicantProfileService? profileService;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.provider.login(email: _email.text, password: _password.text);
    if (mounted && widget.provider.state == AuthState.authenticated) {
      _password.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PowerHR Login')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.provider,
          builder: (context, _) {
            final provider = widget.provider;
            if (provider.state == AuthState.authenticated &&
                provider.identity != null) {
              return WorkspaceView(
                identity: provider.identity!,
                onSignOut: provider.logout,
                profileService: widget.profileService,
              );
            }
            final busy =
                provider.state == AuthState.signingIn ||
                provider.state == AuthState.restoring;
            if (busy) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Sign in',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text('Use an existing PowerHR test account.'),
                        if (provider.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            provider.errorMessage!,
                            key: const Key('login-error'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        if (provider.state ==
                            AuthState.verificationUnavailable) ...[
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: provider.restore,
                            child: const Text('Retry session verification'),
                          ),
                          OutlinedButton(
                            onPressed: provider.logout,
                            child: const Text('Clear stored session'),
                          ),
                        ],
                        const SizedBox(height: 24),
                        TextFormField(
                          key: const Key('login-email'),
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter your email.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('login-password'),
                          controller: _password,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Enter your password.'
                              : null,
                          onFieldSubmitted: (_) => _signIn(),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          key: const Key('login-submit'),
                          onPressed: _signIn,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text('Sign in'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
