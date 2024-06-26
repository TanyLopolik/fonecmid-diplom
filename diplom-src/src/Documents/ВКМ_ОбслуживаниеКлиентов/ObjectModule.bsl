#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область ОбработчикиСобытий

Процедура ОбработкаЗаполнения(ДанныеЗаполнения, ТекстЗаполнения, СтандартнаяОбработка)
	
	Ответственный = Пользователи.ТекущийПользователь();
	
КонецПроцедуры


Процедура ПриЗаписи(Отказ)
	
	Если ОбменДанными.Загрузка тогда
		Возврат;
	КонецЕсли;
	
	ТекстСообщения = "";
	
	Если ДополнительныеСвойства <> Неопределено тогда
		
		Если ДополнительныеСвойства.Свойство("ЭтоНовый") тогда
			ТекстСообщения = СтрШаблон("Создан документ Обслуживание клиентов %1 от %2", 
			Номер, 
			Формат(Дата, "ДФ=dd.MM.yyyy;"));
		Иначе
			
			Если ДополнительныеСвойства.Количество() > 0 тогда
				ТекстСообщения = СтрШаблон("Изменен документ Обслуживание клиентов %1 от %2", 
				Номер, 
				Формат(Дата, "ДФ=dd.MM.yyyy;"));	
			КонецЕсли;
			
		КонецЕсли;
		
	 	Для каждого ЭлементСтруктуры из ДополнительныеСвойства цикл
	 		
	 		Если ЭлементСтруктуры.Ключ = "ЭтоНовый" тогда
	 			Продолжить;
	 		КонецЕсли;
	 		
	 		ТекстСообщения = СтрШаблон("%1%2%3: %4", 
	 		ТекстСообщения, 
	 		Символы.ПС, 
	 		ЭлементСтруктуры.Ключ, 
	 		ЭлементСтруктуры.Значение);
	 		
	 	КонецЦикла;
	
	КонецЕсли;
	
	Если НЕ ПустаяСтрока(ТекстСообщения) тогда
		
		УстановитьПривилегированныйРежим(Истина);
		
		НовоеСообщениеБоту = Справочники.ВКМ_УведомленияТелеграмБоту.СоздатьЭлемент();
		НовоеСообщениеБоту.ТекстСообщения = ТекстСообщения;
		НовоеСообщениеБоту.Записать();
		
		УстановитьПривилегированныйРежим(Ложь);
	КонецЕсли;
	
КонецПроцедуры


Процедура ОбработкаПроведения(Отказ, РежимПроведения)
	
	Если ОбщегоНазначения.ЗначениеРеквизитаОбъекта(Договор, "ВидДоговора") <> Перечисления.ВидыДоговоровКонтрагентов.ВКМ_АбонентскоеОбслуживание тогда
		
		ТекстСообщения = "Вид договора не соотвествует документу. Выберите договор с видом Абонентское обслуживание";
		ОбщегоНазначения.СообщитьПользователю(ТекстСообщения, , "Договор", "Объект");
		Отказ = Истина;
			
	КонецЕсли;
	
	Если Дата < ОбщегоНазначения.ЗначениеРеквизитаОбъекта(Договор, "ВКМ_ДатаНачалаДействияДоговора") тогда
			
		ТекстСообщения = "Дата документа не может быть раньше даты начала действия договора";
		ОбщегоНазначения.СообщитьПользователю(ТекстСообщения, , "Дата", "Объект");
		Отказ = Истина;
			
	КонецЕсли;
		
	Если Дата > ОбщегоНазначения.ЗначениеРеквизитаОбъекта(Договор, "ВКМ_ДатаОкончанияДействияДоговора") тогда
			
		ТекстСообщения = "Дата документа не может быть позже даты окончания действия договора";
		ОбщегоНазначения.СообщитьПользователю(ТекстСообщения, , "Дата", "Объект");
		Отказ = Истина;
		
	КонецЕсли;
		
	ПроцентОплатыОтРаботы = ПолучитьПроцентОплатыСпециалиста();
	Если ПроцентОплатыОтРаботы = Неопределено тогда
		
		ТекстСообщения = СтрШаблон("Для сотрудника %1 не установлен процент оплаты", Специалист);
		ОбщегоНазначения.СообщитьПользователю(ТекстСообщения, , "Специалист", "Объект");
		Отказ = Истина;
		
	КонецЕсли;	
		
	Если Отказ тогда
		Возврат;
	КонецЕсли;
	
	СуммаПоДокументу = 0;	
	СформироватьДвиженияВКМ_ВыполненныеКлиентуРаботы(СуммаПоДокументу);
	СформироватьДвиженияВКМ_ВыполненныеСотрудникомРаботы(ПроцентОплатыОтРаботы, СуммаПоДокументу);
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции
Процедура СформироватьДвиженияВКМ_ВыполненныеКлиентуРаботы(СуммаПоДокументу)
	
	Запрос = Новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ
	|	СУММА(ВКМ_ОбслуживаниеКлиентовВыполненныеРаботы.ЧасыКОплатеКлиенту *
	|		ВКМ_ОбслуживаниеКлиентовВыполненныеРаботы.Ссылка.Договор.ВКМ_СтоимостьЧаса) КАК СуммаКОплате,
	|	СУММА(ВКМ_ОбслуживаниеКлиентовВыполненныеРаботы.ЧасыКОплатеКлиенту) КАК КоличествоЧасов,
	|	ВКМ_ОбслуживаниеКлиентовВыполненныеРаботы.Ссылка.Клиент,
	|	ВКМ_ОбслуживаниеКлиентовВыполненныеРаботы.Ссылка.Договор,
	|	ВКМ_ОбслуживаниеКлиентовВыполненныеРаботы.Ссылка.Дата КАК Период
	|ИЗ
	|	Документ.ВКМ_ОбслуживаниеКлиентов.ВыполненныеРаботы КАК ВКМ_ОбслуживаниеКлиентовВыполненныеРаботы
	|ГДЕ
	|	ВКМ_ОбслуживаниеКлиентовВыполненныеРаботы.Ссылка = &Ссылка
	|СГРУППИРОВАТЬ ПО
	|	ВКМ_ОбслуживаниеКлиентовВыполненныеРаботы.Ссылка.Клиент,
	|	ВКМ_ОбслуживаниеКлиентовВыполненныеРаботы.Ссылка.Договор,
	|	ВКМ_ОбслуживаниеКлиентовВыполненныеРаботы.Ссылка.Дата";
	
	Запрос.УстановитьПараметр("Ссылка", Ссылка);
	Результат = Запрос.Выполнить().Выбрать();
	
	Движения.ВКМ_ВыполненныеКлиентуРаботы.Записывать = Истина;
	
	Пока Результат.Следующий() цикл
		Движение = Движения.ВКМ_ВыполненныеКлиентуРаботы.Добавить();
		ЗаполнитьЗначенияСвойств(Движение, Результат);
		СуммаПоДокументу = СуммаПоДокументу + Результат.СуммаКОплате;
	КонецЦикла;
	
КонецПроцедуры

Функция ПолучитьПроцентОплатыСпециалиста()

	Запрос = Новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ
	|	ВКМ_УсловияОплатыСотрудниковСрезПоследних.ПроцентОтРабот
	|ИЗ
	|	РегистрСведений.ВКМ_УсловияОплатыСотрудников.СрезПоследних(&ДатаДокумента, Сотрудник = &Специалист) КАК
	|		ВКМ_УсловияОплатыСотрудниковСрезПоследних";
	
	Запрос.УстановитьПараметр("ДатаДокумента", Дата);
	Запрос.УстановитьПараметр("Специалист", Специалист);
	
	Результат = Запрос.Выполнить();
	Если Результат.Пустой() тогда
		Возврат Неопределено;
	КонецЕсли;
	
	Выборка = Результат.Выбрать();
	Выборка.Следующий();
	
	Возврат Выборка.ПроцентОтРабот;
	
КонецФункции

Процедура СформироватьДвиженияВКМ_ВыполненныеСотрудникомРаботы(ПроцентОплатыОтРаботы, СуммаПоДокументу)
	
	Движения.ВКМ_ВыполненныеСотрудникомРаботы.Записывать = Истина;
	
	Движение = Движения.ВКМ_ВыполненныеСотрудникомРаботы.Добавить();
	Движение.Период = Дата;
	Движение.Сотрудник = Специалист;
	Движение.ЧасовКОплате = ВыполненныеРаботы.Итог("ФактическиПотраченоЧасов");
	Движение.СуммаКОплате = СуммаПоДокументу* ПроцентОплатыОтРаботы/100;
	
КонецПроцедуры
	
#КонецОбласти

#КонецЕсли
