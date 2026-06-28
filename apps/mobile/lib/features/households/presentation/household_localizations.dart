import 'package:flutter/widgets.dart';

import '../../../core/localization/app_localizations.dart';
import '../domain/household_summary.dart';

extension HouseholdLocalizations on BuildContext {
  String get householdTitle => l10n.languageCode == 'ru' ? 'Дом' : 'Household';
  String get householdSubtitle => l10n.languageCode == 'ru'
      ? 'Выберите дом, с которым вы сейчас работаете.'
      : 'Choose the household you are working with.';
  String get householdActive => l10n.languageCode == 'ru' ? 'Активный дом' : 'Active household';

  String householdRole(HouseholdRole role) {
    return switch ((l10n.languageCode, role)) {
      ('ru', HouseholdRole.owner) => 'Владелец',
      ('ru', HouseholdRole.member) => 'Участник',
      ('en', HouseholdRole.owner) => 'Owner',
      ('en', HouseholdRole.member) => 'Member',
      _ => 'Member',
    };
  }

  String get householdSwitched => l10n.languageCode == 'ru' ? 'Активный дом изменен.' : 'Active household changed.';
  String get createHousehold => l10n.languageCode == 'ru' ? 'Новый дом' : 'New household';
  String get renameHousehold => l10n.languageCode == 'ru' ? 'Переименовать дом' : 'Rename household';
  String get householdName => l10n.languageCode == 'ru' ? 'Название дома' : 'Household name';
  String get householdCreated => l10n.languageCode == 'ru' ? 'Новый дом создан и выбран.' : 'New household created and selected.';
  String get householdRenamed => l10n.languageCode == 'ru' ? 'Название дома обновлено.' : 'Household name updated.';
  String get noHouseholdsTitle => l10n.languageCode == 'ru' ? 'Нет доступных домов' : 'No households available';
  String get noHouseholdsBody => l10n.languageCode == 'ru'
      ? 'Создайте аккаунт заново или попросите владельца добавить вас в общий дом.'
      : 'Create an account again or ask an owner to add you to a shared household.';
  String get householdMembersTitle => l10n.languageCode == 'ru' ? 'Участники дома' : 'Household members';
  String get addHouseholdMember => l10n.languageCode == 'ru' ? 'Добавить участника' : 'Add member';
  String get memberEmailHint => l10n.languageCode == 'ru' ? 'Email зарегистрированного пользователя' : 'Registered user email';
  String get householdMemberAdded => l10n.languageCode == 'ru' ? 'Участник добавлен.' : 'Member added.';
  String get householdMemberRemoved => l10n.languageCode == 'ru' ? 'Участник удален.' : 'Member removed.';
  String get removeHouseholdMember => l10n.languageCode == 'ru' ? 'Удалить участника' : 'Remove member';
  String get removeMemberConfirmTitle => l10n.languageCode == 'ru' ? 'Удалить участника?' : 'Remove this member?';
  String get removeMemberConfirmBody => l10n.languageCode == 'ru'
      ? 'Участник потеряет доступ к вещам, гарантиям и обслуживанию этого дома.'
      : 'This person will lose access to this household’s items, warranties, and maintenance.';
  String get householdMembersReadOnly => l10n.languageCode == 'ru'
      ? 'Только владелец дома может менять состав участников.'
      : 'Only the household owner can manage members.';

  String get invitationsTitle => l10n.languageCode == 'ru' ? 'Приглашения' : 'Invitations';
  String get createInvitation => l10n.languageCode == 'ru' ? 'Создать код приглашения' : 'Create invite code';
  String get joinHousehold => l10n.languageCode == 'ru' ? 'Вступить по коду' : 'Join with code';
  String get invitationCode => l10n.languageCode == 'ru' ? 'Код приглашения' : 'Invitation code';
  String get invitationCodeHint => l10n.languageCode == 'ru'
      ? 'Вставьте код вида HL-XXXX-XXXX-XXXX-XXXX-XXXX'
      : 'Paste a code like HL-XXXX-XXXX-XXXX-XXXX-XXXX';
  String get invitationLifetime => l10n.languageCode == 'ru' ? 'Срок действия кода' : 'Code lifetime';
  String get invitationLifetime24Hours => l10n.languageCode == 'ru' ? '24 часа' : '24 hours';
  String get invitationLifetime72Hours => l10n.languageCode == 'ru' ? '3 дня' : '3 days';
  String get invitationLifetime168Hours => l10n.languageCode == 'ru' ? '7 дней' : '7 days';
  String demoInvitationCode(String code) => l10n.languageCode == 'ru' ? 'Демо-код: $code' : 'Demo code: $code';
  String get invitationCodeCreated => l10n.languageCode == 'ru' ? 'Код создан. Передайте его участнику.' : 'Code created. Share it with the person you invite.';
  String get invitationCodeCopied => l10n.languageCode == 'ru' ? 'Код скопирован.' : 'Code copied.';
  String get invitationAccepted => l10n.languageCode == 'ru' ? 'Вы присоединились к дому.' : 'You joined the household.';
  String get invitationExpires => l10n.languageCode == 'ru' ? 'Действует до' : 'Expires';
  String get noActiveInvitations => l10n.languageCode == 'ru' ? 'Активных приглашений пока нет.' : 'There are no active invitations.';
  String get revokeInvitation => l10n.languageCode == 'ru' ? 'Отозвать приглашение' : 'Revoke invitation';
  String get revokeInvitationTitle => l10n.languageCode == 'ru' ? 'Отозвать приглашение?' : 'Revoke invitation?';
  String get revokeInvitationBody => l10n.languageCode == 'ru' ? 'Этот код сразу перестанет работать.' : 'This code will stop working immediately.';
  String get invitationCodeSecurityHint => l10n.languageCode == 'ru'
      ? 'Код показывается только один раз. Не публикуйте его в открытом доступе.'
      : 'The code is shown only once. Do not post it publicly.';
}
