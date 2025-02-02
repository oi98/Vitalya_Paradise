import { round } from 'common/math';
import { useBackend } from '../backend';
import { Window } from '../layouts';
import {
  Box,
  Button,
  Stack,
  Icon,
  Knob,
  LabeledList,
  Section,
  Tabs,
  ProgressBar,
} from '../components';

const stats = [
  ['good', 'В сознании'],
  ['average', 'Без сознания'],
  ['bad', 'Зафиксирована смерть'],
];

const damages = [
  ['Удушение', 'oxyLoss'],
  ['Токсины', 'toxLoss'],
  ['Физические повреждения', 'bruteLoss'],
  ['Ожоги', 'fireLoss'],
];

const damageRange = {
  average: [0.25, 0.5],
  bad: [0.5, Infinity],
};

const tempColors = [
  'bad',
  'average',
  'average',
  'good',
  'average',
  'average',
  'bad',
];

export const OperatingComputer = (props, context) => {
  const { act, data } = useBackend(context);
  const { hasOccupant, choice } = data;
  let body;
  if (!choice) {
    body = hasOccupant ? (
      <OperatingComputerPatient />
    ) : (
      <OperatingComputerUnoccupied />
    );
  } else {
    body = <OperatingComputerOptions />;
  }
  return (
    <Window width={650} height={455}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Tabs>
              <Tabs.Tab
                selected={!choice}
                icon="user"
                onClick={() => act('choiceOff')}
              >
                Пациент
              </Tabs.Tab>
              <Tabs.Tab
                selected={!!choice}
                icon="cog"
                onClick={() => act('choiceOn')}
              >
                Настройки
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            <Section fill scrollable>
              {body}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const OperatingComputerPatient = (props, context) => {
  const { data } = useBackend(context);
  const { occupant } = data;
  return (
    <Stack fill vertical>
      <Stack.Item grow>
        <Section fill title="Пациент">
          <LabeledList>
            <LabeledList.Item label="Имя">{occupant.name}</LabeledList.Item>
            <LabeledList.Item label="Состояние" color={stats[occupant.stat][0]}>
              {stats[occupant.stat][1]}
            </LabeledList.Item>
            <LabeledList.Item label="Оценка здоровья">
              <ProgressBar
                min="0"
                max={occupant.maxHealth}
                value={occupant.health / occupant.maxHealth}
                ranges={{
                  good: [0.5, Infinity],
                  average: [0, 0.5],
                  bad: [-Infinity, 0],
                }}
              />
            </LabeledList.Item>
            {damages.map((d, i) => (
              <LabeledList.Item key={i} label={d[0]}>
                <ProgressBar
                  key={i}
                  min="0"
                  max="100"
                  value={occupant[d[1]] / 100}
                  ranges={damageRange}
                >
                  {round(occupant[d[1]])}
                </ProgressBar>
              </LabeledList.Item>
            ))}
            <LabeledList.Item label="Температура тела">
              <ProgressBar
                min="0"
                max={occupant.maxTemp}
                value={occupant.bodyTemperature / occupant.maxTemp}
                color={tempColors[occupant.temperatureSuitability + 3]}
              >
                {round(occupant.btCelsius)}&deg;C, {round(occupant.btFaren)}
                &deg;F
              </ProgressBar>
            </LabeledList.Item>
            {!!occupant.hasBlood && (
              <>
                <LabeledList.Item label="Уровень крови">
                  <ProgressBar
                    min="0"
                    max={occupant.bloodMax}
                    value={occupant.bloodLevel / occupant.bloodMax}
                    ranges={{
                      bad: [-Infinity, 0.6],
                      average: [0.6, 0.9],
                      good: [0.6, Infinity],
                    }}
                  >
                    {occupant.bloodPercent}%, {occupant.bloodLevel}cl
                  </ProgressBar>
                </LabeledList.Item>
                <LabeledList.Item label="Пульс">
                  {occupant.pulse} уд/мин
                </LabeledList.Item>
              </>
            )}
          </LabeledList>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Текущие операции" level="2">
          {occupant.inSurgery ? (
            occupant.surgeries.map(
              ({ bodypartName, surgeryName, stepName }) => (
                <Section title={bodypartName} level="4" key={bodypartName}>
                  <LabeledList>
                    <LabeledList.Item label="Операция">
                      {surgeryName}
                    </LabeledList.Item>
                    <LabeledList.Item label="Следующий этап">
                      {stepName}
                    </LabeledList.Item>
                  </LabeledList>
                </Section>
              )
            )
          ) : (
            <Box color="label">Операции в данный момент не проводятся.</Box>
          )}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const OperatingComputerUnoccupied = () => {
  return (
    <Stack fill>
      <Stack.Item grow align="center" textAlign="center" color="label">
        <Icon name="user-slash" mb="0.5rem" size="5" />
        <br />
        Пациент не обнаружен.
      </Stack.Item>
    </Stack>
  );
};

const OperatingComputerOptions = (props, context) => {
  const { act, data } = useBackend(context);
  const { verbose, health, healthAlarm, oxy, oxyAlarm, crit } = data;
  return (
    <LabeledList>
      <LabeledList.Item label="Динамик">
        <Button
          selected={verbose}
          icon={verbose ? 'toggle-on' : 'toggle-off'}
          content={verbose ? 'Включён' : 'Выключен'}
          onClick={() => act(verbose ? 'verboseOff' : 'verboseOn')}
        />
      </LabeledList.Item>
      <LabeledList.Item label="Оповещать о состоянии пациента">
        <Button
          selected={health}
          icon={health ? 'toggle-on' : 'toggle-off'}
          content={health ? 'Включено' : 'Выключено'}
          onClick={() => act(health ? 'healthOff' : 'healthOn')}
        />
      </LabeledList.Item>
      <LabeledList.Item label="Порог оповещения о состоянии">
        <Knob
          bipolar
          minValue={-100}
          maxValue={100}
          value={healthAlarm}
          stepPixelSize={5}
          ml="0"
          onChange={(e, val) =>
            act('health_adj', {
              new: val,
            })
          }
        />
      </LabeledList.Item>
      <LabeledList.Item label="Оповещать о дыхании пациента">
        <Button
          selected={oxy}
          icon={oxy ? 'toggle-on' : 'toggle-off'}
          content={oxy ? 'Включено' : 'Выключено'}
          onClick={() => act(oxy ? 'oxyOff' : 'oxyOn')}
        />
      </LabeledList.Item>
      <LabeledList.Item label="Порог оповещения о дыхании">
        <Knob
          bipolar
          minValue={-100}
          maxValue={100}
          value={oxyAlarm}
          stepPixelSize={5}
          ml="0"
          onChange={(e, val) =>
            act('oxy_adj', {
              new: val,
            })
          }
        />
      </LabeledList.Item>
      <LabeledList.Item label="Оповещать о критическом состоянии пациента">
        <Button
          selected={crit}
          icon={crit ? 'toggle-on' : 'toggle-off'}
          content={crit ? 'Включено' : 'Выключено'}
          onClick={() => act(crit ? 'critOff' : 'critOn')}
        />
      </LabeledList.Item>
    </LabeledList>
  );
};
